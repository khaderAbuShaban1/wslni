<?php

namespace Database\Seeders;

use App\Models\AppSetting;
use App\Models\Complaint;
use App\Models\DriverProfile;
use App\Models\Promotion;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletDeposit;
use App\Models\WalletPaymentAccount;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'kabushaban2@smail.ucas.edu.ps'],
            [
                'name' => 'خضر خالد خضر أبو شعبان',
                'phone' => '0599480926',
                'password' => Hash::make('123123123'),
                'role' => 'admin',
                'account_status' => 'active',
                'wallet_balance' => 0,
                'email_verified_at' => now(),
            ]
        );

        AppSetting::updateOrCreate(
            ['key' => 'commission_percent'],
            ['value' => '15']
        );

        $bankAccount = WalletPaymentAccount::updateOrCreate(
            ['name' => 'بنك فلسطين'],
            [
                'type' => 'bank',
                'account_holder_name' => 'Wslni',
                'account_number' => '123456789',
                'phone_number' => null,
                'instructions' => 'حوّل المبلغ إلى الحساب البنكي ثم ارفع صورة الإشعار من المحفظة.',
                'is_active' => true,
                'sort_order' => 1,
            ]
        );

        $jawwalPayAccount = WalletPaymentAccount::updateOrCreate(
            ['name' => 'جوال Pay'],
            [
                'type' => 'mobile_wallet',
                'account_holder_name' => 'Wslni',
                'account_number' => null,
                'phone_number' => '0599480926',
                'instructions' => 'حوّل المبلغ إلى رقم المحفظة ثم ارفع صورة الإشعار.',
                'is_active' => true,
                'sort_order' => 2,
            ]
        );

        $palPayAccount = WalletPaymentAccount::updateOrCreate(
            ['name' => 'PalPay'],
            [
                'type' => 'mobile_wallet',
                'account_holder_name' => 'Wslni',
                'account_number' => null,
                'phone_number' => '0599480926',
                'instructions' => 'استخدم رقم المحفظة الظاهر ثم أرفق إشعار الدفع للمراجعة.',
                'is_active' => true,
                'sort_order' => 3,
            ]
        );

        $customers = collect([
            [
                'name' => 'ليان عوض',
                'email' => 'lian.awad@example.com',
                'phone' => '0597001001',
                'status' => 'active',
                'wallet_balance' => 120.00,
            ],
            [
                'name' => 'آدم المصري',
                'email' => 'adam.masri@example.com',
                'phone' => '0597001002',
                'status' => 'active',
                'wallet_balance' => 0.00,
            ],
            [
                'name' => 'نور الشامي',
                'email' => 'noor.shami@example.com',
                'phone' => '0597001003',
                'status' => 'suspended',
                'wallet_balance' => 0.00,
            ],
            [
                'name' => 'رنا أبو شقرة',
                'email' => 'rana.abushaqra@example.com',
                'phone' => '0597001004',
                'status' => 'active',
                'wallet_balance' => 40.00,
            ],
        ])->map(function (array $customer) {
            return User::updateOrCreate(
                ['email' => $customer['email']],
                [
                    'name' => $customer['name'],
                    'phone' => $customer['phone'],
                    'password' => Hash::make('123123123'),
                    'role' => 'customer',
                    'account_status' => $customer['status'],
                    'wallet_balance' => $customer['wallet_balance'],
                    'email_verified_at' => now(),
                ]
            );
        });

        $drivers = collect([
            [
                'name' => 'أحمد دبابسة',
                'email' => 'ahmad.driver@example.com',
                'phone' => '0597002001',
                'license' => 'D-10482',
                'vehicle_type' => 'هيونداي أكسنت',
                'plate' => '1122-أ',
                'approval_status' => 'approved',
                'online' => true,
                'rating' => '4.92',
            ],
            [
                'name' => 'سامي جودة',
                'email' => 'sami.driver@example.com',
                'phone' => '0597002002',
                'license' => 'D-20431',
                'vehicle_type' => 'كيا ريو',
                'plate' => '7744-ب',
                'approval_status' => 'approved',
                'online' => false,
                'rating' => '4.74',
            ],
            [
                'name' => 'وسام قاسم',
                'email' => 'wissam.driver@example.com',
                'phone' => '0597002003',
                'license' => 'D-30990',
                'vehicle_type' => 'تويوتا كورولا',
                'plate' => '8899-ج',
                'approval_status' => 'pending',
                'online' => false,
                'rating' => '4.60',
            ],
        ])->map(function (array $driver) {
            $user = User::updateOrCreate(
                ['email' => $driver['email']],
                [
                    'name' => $driver['name'],
                    'phone' => $driver['phone'],
                    'password' => Hash::make('123123123'),
                    'role' => 'driver',
                    'account_status' => 'active',
                    'wallet_balance' => 0,
                    'email_verified_at' => now(),
                ]
            );

            DriverProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'license_number' => $driver['license'],
                    'vehicle_type' => $driver['vehicle_type'],
                    'vehicle_plate' => $driver['plate'],
                    'approval_status' => $driver['approval_status'],
                    'approved_at' => $driver['approval_status'] === 'approved' ? now()->subDays(5) : null,
                    'rejection_reason' => null,
                    'is_online' => $driver['online'],
                    'current_lat' => 31.9515,
                    'current_lng' => 35.9239,
                    'rating' => $driver['rating'],
                ]
            );

            return $user;
        });

        $requestedRide = RideRequest::updateOrCreate(
            ['pickup_address' => 'رام الله - الإرسال'],
            [
                'customer_id' => $customers[0]->id,
                'driver_id' => null,
                'status' => 'requested',
                'pickup_address' => 'رام الله - الإرسال',
                'pickup_lat' => 31.9038,
                'pickup_lng' => 35.2034,
                'dropoff_address' => 'البيرة - وسط المدينة',
                'dropoff_lat' => 31.9061,
                'dropoff_lng' => 35.2125,
                'fare_estimate' => 12.50,
                'actual_fare' => null,
                'distance_km' => 3.20,
                'commission_percent' => 15,
                'platform_fee' => null,
                'notes' => 'الراكب مستعجل ويريد أقصر طريق.',
                'requested_at' => now()->subHours(2),
            ]
        );

        $acceptedRide = RideRequest::updateOrCreate(
            ['pickup_address' => 'القدس - بيت حنينا'],
            [
                'customer_id' => $customers[1]->id,
                'driver_id' => $drivers[0]->id,
                'status' => 'accepted',
                'pickup_address' => 'القدس - بيت حنينا',
                'pickup_lat' => 31.8388,
                'pickup_lng' => 35.2350,
                'dropoff_address' => 'رام الله - الماصيون',
                'dropoff_lat' => 31.9050,
                'dropoff_lng' => 35.2043,
                'fare_estimate' => 28.00,
                'actual_fare' => 28.00,
                'distance_km' => 15.80,
                'commission_percent' => 15,
                'platform_fee' => 4.20,
                'notes' => 'تم قبول الرحلة من السائق.',
                'requested_at' => now()->subHours(4),
                'accepted_at' => now()->subHours(3),
            ]
        );

        $inProgressRide = RideRequest::updateOrCreate(
            ['pickup_address' => 'نابلس - دوار الشهداء'],
            [
                'customer_id' => $customers[3]->id,
                'driver_id' => $drivers[1]->id,
                'status' => 'in_progress',
                'pickup_address' => 'نابلس - دوار الشهداء',
                'pickup_lat' => 32.2211,
                'pickup_lng' => 35.2544,
                'dropoff_address' => 'نابلس - رفيديا',
                'dropoff_lat' => 32.2339,
                'dropoff_lng' => 35.2229,
                'fare_estimate' => 16.00,
                'actual_fare' => 16.50,
                'distance_km' => 4.70,
                'commission_percent' => 15,
                'platform_fee' => 2.48,
                'notes' => 'الرحلة قيد التنفيذ الآن.',
                'requested_at' => now()->subHour(),
                'accepted_at' => now()->subMinutes(50),
            ]
        );

        RideRequest::updateOrCreate(
            ['pickup_address' => 'الخليل - رأس الجورة'],
            [
                'customer_id' => $customers[2]->id,
                'driver_id' => $drivers[0]->id,
                'status' => 'completed',
                'pickup_address' => 'الخليل - رأس الجورة',
                'pickup_lat' => 31.5307,
                'pickup_lng' => 35.0944,
                'dropoff_address' => 'الخليل - الجامعة',
                'dropoff_lat' => 31.5164,
                'dropoff_lng' => 35.1066,
                'fare_estimate' => 18.00,
                'actual_fare' => 19.00,
                'distance_km' => 5.10,
                'commission_percent' => 15,
                'platform_fee' => 2.85,
                'notes' => 'رحلة مكتملة مع تقييم جيد.',
                'requested_at' => now()->subDay(),
                'accepted_at' => now()->subDay()->addMinutes(10),
                'completed_at' => now()->subDay()->addMinutes(35),
            ]
        );

        RideRequest::updateOrCreate(
            ['pickup_address' => 'بيت لحم - الدهيشة'],
            [
                'customer_id' => $customers[0]->id,
                'driver_id' => $drivers[1]->id,
                'status' => 'cancelled',
                'pickup_address' => 'بيت لحم - الدهيشة',
                'pickup_lat' => 31.7153,
                'pickup_lng' => 35.1951,
                'dropoff_address' => 'بيت لحم - المهد',
                'dropoff_lat' => 31.7054,
                'dropoff_lng' => 35.2007,
                'fare_estimate' => 9.00,
                'actual_fare' => null,
                'distance_km' => 2.30,
                'commission_percent' => 15,
                'platform_fee' => null,
                'notes' => 'تم الإلغاء قبل الانطلاق.',
                'requested_at' => now()->subHours(6),
            ]
        );

        Complaint::updateOrCreate(
            ['message' => 'تأخر السائق أكثر من 20 دقيقة عند الاستلام.'],
            [
                'user_id' => $customers[0]->id,
                'ride_request_id' => $requestedRide->id,
                'category' => 'التأخير',
                'status' => 'open',
                'resolution_note' => null,
                'resolved_at' => null,
            ]
        );

        Complaint::updateOrCreate(
            ['message' => 'السائق أنهى الرحلة بشكل سريع لكن لم يظهر التقييم.'],
            [
                'user_id' => $customers[1]->id,
                'ride_request_id' => $acceptedRide->id,
                'category' => 'الدعم الفني',
                'status' => 'resolved',
                'resolution_note' => 'تم التأكد من التقييم وإرسال إشعار للراكب.',
                'resolved_at' => now()->subHours(8),
            ]
        );

        Complaint::updateOrCreate(
            ['message' => 'طلب تعديل وسيلة الدفع الخاصة بالرحلة.'],
            [
                'user_id' => $customers[3]->id,
                'ride_request_id' => $inProgressRide->id,
                'category' => 'الدفع',
                'status' => 'open',
                'resolution_note' => null,
                'resolved_at' => null,
            ]
        );

        Promotion::updateOrCreate(
            ['code' => 'WELCOME15'],
            [
                'title' => 'خصم الترحيب',
                'type' => 'discount',
                'value' => 15,
                'is_active' => true,
                'starts_at' => now()->subDays(5),
                'ends_at' => now()->addDays(20),
                'notes' => 'خصم ترحيبي للرحلات الأولى.',
            ]
        );

        Promotion::updateOrCreate(
            ['code' => 'RAMADAN20'],
            [
                'title' => 'عرض الموسم',
                'type' => 'discount',
                'value' => 20,
                'is_active' => false,
                'starts_at' => now()->subMonths(2),
                'ends_at' => now()->subMonth(),
                'notes' => 'عرض موسمي انتهى.',
            ]
        );

        Promotion::updateOrCreate(
            ['code' => 'RIDEFREE'],
            [
                'title' => 'رحلة مجانية قصيرة',
                'type' => 'free_ride',
                'value' => 12,
                'is_active' => true,
                'starts_at' => now()->subDay(),
                'ends_at' => now()->addDays(10),
                'notes' => 'مخصص للرحلات القصيرة داخل المدينة.',
            ]
        );

        $bankReceiptPath = $this->storeDemoReceipt('demo-bank-palestine.svg', $bankAccount->name, 'REF-2026-001', '120.00');
        $jawwalPayReceiptPath = $this->storeDemoReceipt('demo-jawwal-pay.svg', $jawwalPayAccount->name, 'REF-2026-002', '75.00');
        $palPayReceiptPath = $this->storeDemoReceipt('demo-palpay.svg', $palPayAccount->name, 'REF-2026-003', '40.00');
        $rejectedReceiptPath = $this->storeDemoReceipt('demo-rejected-bank.svg', $bankAccount->name, 'REF-2026-004', '25.00');

        WalletDeposit::updateOrCreate(
            ['reference_number' => 'REF-2026-001'],
            [
                'user_id' => $customers[0]->id,
                'wallet_payment_account_id' => $bankAccount->id,
                'amount' => 120.00,
                'bank_name' => $bankAccount->name,
                'receipt_path' => $bankReceiptPath,
                'status' => 'approved',
                'note' => 'إيداع بنكي أولي مع صورة إشعار تجريبية.',
                'reviewed_by' => $admin->id,
                'reviewed_at' => now()->subDays(2),
                'wallet_credited_at' => now()->subDays(2),
            ]
        );

        WalletDeposit::updateOrCreate(
            ['reference_number' => 'REF-2026-002'],
            [
                'user_id' => $customers[1]->id,
                'wallet_payment_account_id' => $jawwalPayAccount->id,
                'amount' => 75.00,
                'bank_name' => $jawwalPayAccount->name,
                'receipt_path' => $jawwalPayReceiptPath,
                'status' => 'pending',
                'note' => 'إشعار جوال Pay بانتظار الاعتماد.',
                'reviewed_by' => null,
                'reviewed_at' => null,
                'wallet_credited_at' => null,
            ]
        );

        WalletDeposit::updateOrCreate(
            ['reference_number' => 'REF-2026-003'],
            [
                'user_id' => $customers[3]->id,
                'wallet_payment_account_id' => $palPayAccount->id,
                'amount' => 40.00,
                'bank_name' => $palPayAccount->name,
                'receipt_path' => $palPayReceiptPath,
                'status' => 'approved',
                'note' => 'تم اعتماد إشعار PalPay يدويًا.',
                'reviewed_by' => $admin->id,
                'reviewed_at' => now()->subDay(),
                'wallet_credited_at' => now()->subDay(),
            ]
        );

        WalletDeposit::updateOrCreate(
            ['reference_number' => 'REF-2026-004'],
            [
                'user_id' => $customers[2]->id,
                'wallet_payment_account_id' => $bankAccount->id,
                'amount' => 25.00,
                'bank_name' => $bankAccount->name,
                'receipt_path' => $rejectedReceiptPath,
                'status' => 'rejected',
                'note' => 'إشعار تجريبي مرفوض لعرض حالة الرفض.',
                'reviewed_by' => $admin->id,
                'reviewed_at' => now()->subHours(6),
                'wallet_credited_at' => null,
            ]
        );
    }

    private function storeDemoReceipt(string $filename, string $method, string $reference, string $amount): string
    {
        $path = "wallet-deposits/{$filename}";
        $safeMethod = htmlspecialchars($method, ENT_XML1 | ENT_COMPAT, 'UTF-8');
        $safeReference = htmlspecialchars($reference, ENT_XML1 | ENT_COMPAT, 'UTF-8');
        $safeAmount = htmlspecialchars($amount, ENT_XML1 | ENT_COMPAT, 'UTF-8');

        Storage::disk('public')->put($path, <<<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="900" height="560" viewBox="0 0 900 560">
  <rect width="900" height="560" fill="#f8fbfd"/>
  <rect x="55" y="55" width="790" height="450" rx="28" fill="#ffffff" stroke="#d9e2ec" stroke-width="4"/>
  <circle cx="760" cy="145" r="54" fill="#dff5f1"/>
  <text x="760" y="157" fill="#0f766e" font-size="34" font-family="Arial, sans-serif" font-weight="700" text-anchor="middle">W</text>
  <text x="110" y="135" fill="#0f172a" font-size="34" font-family="Arial, sans-serif" font-weight="700">Wslni Deposit Notice</text>
  <text x="110" y="185" fill="#64748b" font-size="22" font-family="Arial, sans-serif">Payment Method</text>
  <text x="110" y="220" fill="#0f172a" font-size="28" font-family="Arial, sans-serif" font-weight="700">{$safeMethod}</text>
  <text x="110" y="285" fill="#64748b" font-size="22" font-family="Arial, sans-serif">Reference Number</text>
  <text x="110" y="320" fill="#0f172a" font-size="28" font-family="Arial, sans-serif" font-weight="700">{$safeReference}</text>
  <text x="110" y="385" fill="#64748b" font-size="22" font-family="Arial, sans-serif">Amount</text>
  <text x="110" y="425" fill="#0f766e" font-size="42" font-family="Arial, sans-serif" font-weight="700">{$safeAmount} NIS</text>
  <text x="110" y="470" fill="#64748b" font-size="18" font-family="Arial, sans-serif">Demo receipt generated by the database seeder.</text>
</svg>
SVG);

        return $path;
    }
}
