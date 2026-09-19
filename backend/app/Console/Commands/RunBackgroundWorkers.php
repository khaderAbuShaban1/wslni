<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Symfony\Component\Process\PhpExecutableFinder;
use Symfony\Component\Process\Process;

/**
 * Local stand-in for Supervisor: keeps the queue workers and the scheduler
 * alive in one terminal. In production run the same commands under
 * Supervisor/systemd instead.
 */
class RunBackgroundWorkers extends Command
{
    protected $signature = 'app:workers {--workers=3 : Number of parallel queue workers}';

    protected $description = 'Run the queue workers and the scheduler, restarting any that exit';

    /** @var array<string, Process> */
    private array $processes = [];

    /** @var array<string, list<string>> */
    private array $commands = [];

    public function handle(): int
    {
        $php = (new PhpExecutableFinder)->find(false) ?: 'php';

        for ($i = 1; $i <= max(1, (int) $this->option('workers')); $i++) {
            // realtime first so Firebase updates never wait behind push sends.
            // --max-time recycles workers hourly; queue:restart also ends them,
            // and both come back here with freshly loaded code.
            $this->commands["queue-{$i}"] = [
                $php, 'artisan', 'queue:work',
                '--queue=realtime,notifications,default',
                '--sleep=0.5',
                '--timeout=30',
                '--max-time=3600',
            ];
        }
        $this->commands['scheduler'] = [$php, 'artisan', 'schedule:work'];

        foreach (array_keys($this->commands) as $name) {
            $this->start($name);
        }

        $this->components->info('Workers running. Press Ctrl+C to stop.');

        while (true) {
            foreach ($this->processes as $name => $process) {
                $this->flush($name, $process);

                if (! $process->isRunning()) {
                    $this->components->warn("[{$name}] exited with code {$process->getExitCode()}, restarting.");
                    $this->start($name);
                }
            }

            usleep(200_000);
        }
    }

    private function start(string $name): void
    {
        $process = new Process($this->commands[$name], base_path(), null, null, null);
        $process->start();
        $this->processes[$name] = $process;
    }

    private function flush(string $name, Process $process): void
    {
        $output = $process->getIncrementalOutput().$process->getIncrementalErrorOutput();

        foreach (preg_split('/\R/', trim($output)) as $line) {
            if (trim($line) !== '') {
                $this->line("<fg=gray>[{$name}]</> {$line}");
            }
        }
    }
}
