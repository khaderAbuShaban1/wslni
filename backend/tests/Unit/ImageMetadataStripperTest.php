<?php

namespace Tests\Unit;

use App\Support\ImageMetadataStripper;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class ImageMetadataStripperTest extends TestCase
{
    public function test_jpeg_loses_exif_and_comments_but_keeps_orientation_and_image_data(): void
    {
        $scan = "\xFF\xDA\x00\x08\x01\x01\x00\x00\x3F\x00"."\x12\x34\x56\x78"."\xFF\xD9";
        $jpeg = "\xFF\xD8"
            .self::segment(0xE0, "JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
            .self::segment(0xE1, self::exifWithOrientationAndSecret(6, 'SECRET-GPS'))
            .self::segment(0xFE, 'SECRET-COMMENT')
            .self::segment(0xE2, "ICC_PROFILE\x00\x01\x01profile-bytes")
            .self::segment(0xDB, "\x00".str_repeat("\x01", 64))
            .$scan;

        $clean = ImageMetadataStripper::strip($jpeg, 'image/jpeg');

        $this->assertStringNotContainsString('SECRET', $clean);
        $this->assertStringContainsString('JFIF', $clean);
        $this->assertStringContainsString('ICC_PROFILE', $clean);
        $this->assertStringEndsWith($scan, $clean);
        $exif = @exif_read_data('data://image/jpeg;base64,'.base64_encode($clean));
        $this->assertSame(6, (int) ($exif['Orientation'] ?? 0));
    }

    public function test_jpeg_without_rotation_gets_no_exif_segment(): void
    {
        $jpeg = "\xFF\xD8"
            .self::segment(0xE1, self::exifWithOrientationAndSecret(1, 'SECRET-GPS'))
            ."\xFF\xDA\x00\x02"."\x00"."\xFF\xD9";

        $clean = ImageMetadataStripper::strip($jpeg, 'image/jpeg');

        $this->assertStringNotContainsString('Exif', $clean);
        $this->assertStringNotContainsString('SECRET', $clean);
    }

    public function test_png_loses_text_chunks_but_keeps_image_chunks(): void
    {
        $png = self::png(['tEXt' => "Comment\x00SECRET", 'eXIf' => 'SECRET-EXIF']);

        $clean = ImageMetadataStripper::strip($png, 'image/png');

        $this->assertStringNotContainsString('SECRET', $clean);
        foreach (['IHDR', 'IDAT', 'IEND'] as $chunk) {
            $this->assertStringContainsString($chunk, $clean);
        }
        $this->assertSame([8, 8], array_slice(getimagesizefromstring($clean), 0, 2));
    }

    public function test_webp_loses_exif_and_xmp_and_their_header_flags(): void
    {
        $vp8x = "\x0C\x00\x00\x00".str_repeat("\x00", 6);
        $webp = self::webp([
            'VP8X' => $vp8x,
            'VP8L' => "image-data",
            'EXIF' => 'SECRET-EXIF',
            'XMP ' => 'SECRET-XMP',
        ]);

        $clean = ImageMetadataStripper::strip($webp, 'image/webp');

        $this->assertStringNotContainsString('SECRET', $clean);
        $this->assertStringContainsString('image-data', $clean);
        $this->assertSame(0, ord($clean[20]) & 0x0C);
        $this->assertSame(strlen($clean) - 8, unpack('V', substr($clean, 4, 4))[1]);
    }

    public function test_mismatched_content_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);

        ImageMetadataStripper::strip('not an image', 'image/jpeg');
    }

    private static function segment(int $marker, string $payload): string
    {
        return "\xFF".chr($marker).pack('n', strlen($payload) + 2).$payload;
    }

    /** Big-endian TIFF with ImageDescription (stand-in for GPS data) and Orientation. */
    private static function exifWithOrientationAndSecret(int $orientation, string $secret): string
    {
        $text = $secret."\x00";
        $tiff = 'MM'.pack('nN', 42, 8)
            .pack('n', 2)
            .pack('nnNN', 0x010E, 2, strlen($text), 38)
            .pack('nnNnn', 0x0112, 3, 1, $orientation, 0)
            .pack('N', 0)
            .$text;

        return "Exif\x00\x00".$tiff;
    }

    /** @param array<string, string> $extra */
    public static function png(array $extra = [], int $width = 8, int $height = 8): string
    {
        $chunk = fn (string $type, string $data) => pack('N', strlen($data)).$type.$data.pack('N', crc32($type.$data));
        $rows = str_repeat("\x00".str_repeat("\xE9\xB9\x34", $width), $height);

        $out = "\x89PNG\r\n\x1a\n".$chunk('IHDR', pack('NNCCCCC', $width, $height, 8, 2, 0, 0, 0));
        foreach ($extra as $type => $data) {
            $out .= $chunk($type, $data);
        }

        return $out.$chunk('IDAT', gzcompress($rows)).$chunk('IEND', '');
    }

    /** @param array<string, string> $chunks */
    private static function webp(array $chunks): string
    {
        $body = '';
        foreach ($chunks as $type => $data) {
            $body .= $type.pack('V', strlen($data)).$data.(strlen($data) % 2 ? "\x00" : '');
        }

        return 'RIFF'.pack('V', strlen($body) + 4).'WEBP'.$body;
    }
}
