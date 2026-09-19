<?php

namespace App\Support;

use InvalidArgumentException;

/**
 * Removes EXIF/XMP/text metadata from uploaded images without needing GD.
 * Phone photos carry the GPS position they were taken at, and profile photos
 * are shown to strangers (drivers see customers and vice versa).
 */
class ImageMetadataStripper
{
    public static function strip(string $bytes, string $mime): string
    {
        return match ($mime) {
            'image/jpeg' => self::jpeg($bytes),
            'image/png' => self::png($bytes),
            'image/webp' => self::webp($bytes),
            default => throw new InvalidArgumentException("Unsupported image type {$mime}."),
        };
    }

    /** Drops APP1–APP15 and comment segments, keeping the ICC profile and EXIF orientation. */
    private static function jpeg(string $bytes): string
    {
        if (substr($bytes, 0, 2) !== "\xFF\xD8") {
            throw new InvalidArgumentException('Not a JPEG file.');
        }

        $orientation = self::jpegOrientation($bytes);
        $out = "\xFF\xD8";
        if ($orientation > 1 && $orientation <= 8) {
            $out .= self::orientationSegment($orientation);
        }

        $offset = 2;
        $length = strlen($bytes);
        while ($offset + 4 <= $length) {
            if ($bytes[$offset] !== "\xFF") {
                throw new InvalidArgumentException('Malformed JPEG segment.');
            }
            // Markers may be preceded by any number of 0xFF fill bytes.
            if ($bytes[$offset + 1] === "\xFF") {
                $offset++;

                continue;
            }
            $marker = ord($bytes[$offset + 1]);

            // Start of scan: the compressed image data follows to the end.
            if ($marker === 0xDA) {
                return $out.substr($bytes, $offset);
            }

            $size = unpack('n', substr($bytes, $offset + 2, 2))[1];
            $segment = substr($bytes, $offset, $size + 2);
            $isColorProfile = $marker === 0xE2 && str_starts_with(substr($segment, 4), 'ICC_PROFILE');
            $isMetadata = ($marker >= 0xE1 && $marker <= 0xEF) || $marker === 0xFE;
            if (! $isMetadata || $isColorProfile) {
                $out .= $segment;
            }
            $offset += $size + 2;
        }

        throw new InvalidArgumentException('JPEG has no image data.');
    }

    private static function jpegOrientation(string $bytes): int
    {
        $exif = @exif_read_data('data://image/jpeg;base64,'.base64_encode($bytes));

        return is_array($exif) ? (int) ($exif['Orientation'] ?? 1) : 1;
    }

    /** A minimal APP1 Exif segment holding only the Orientation tag. */
    private static function orientationSegment(int $orientation): string
    {
        $tiff = 'MM'.pack('nN', 42, 8)       // big-endian TIFF header, IFD at offset 8
            .pack('n', 1)                     // one entry
            .pack('nnNnn', 0x0112, 3, 1, $orientation, 0)
            .pack('N', 0);                    // no next IFD
        $payload = "Exif\x00\x00".$tiff;

        return "\xFF\xE1".pack('n', strlen($payload) + 2).$payload;
    }

    /** Keeps only chunks that affect how the image renders. */
    private static function png(string $bytes): string
    {
        if (substr($bytes, 0, 8) !== "\x89PNG\r\n\x1a\n") {
            throw new InvalidArgumentException('Not a PNG file.');
        }

        $metadata = ['tEXt', 'zTXt', 'iTXt', 'eXIf', 'tIME'];
        $out = substr($bytes, 0, 8);
        $offset = 8;
        $length = strlen($bytes);
        while ($offset + 12 <= $length) {
            $size = unpack('N', substr($bytes, $offset, 4))[1];
            $type = substr($bytes, $offset + 4, 4);
            $chunk = substr($bytes, $offset, $size + 12);
            if (! in_array($type, $metadata, true)) {
                $out .= $chunk;
            }
            $offset += $size + 12;
            if ($type === 'IEND') {
                return $out;
            }
        }

        throw new InvalidArgumentException('PNG has no end chunk.');
    }

    /** Drops EXIF/XMP chunks and clears their flags in the VP8X header. */
    private static function webp(string $bytes): string
    {
        if (substr($bytes, 0, 4) !== 'RIFF' || substr($bytes, 8, 4) !== 'WEBP') {
            throw new InvalidArgumentException('Not a WebP file.');
        }

        $body = '';
        $offset = 12;
        $length = strlen($bytes);
        while ($offset + 8 <= $length) {
            $type = substr($bytes, $offset, 4);
            $size = unpack('V', substr($bytes, $offset + 4, 4))[1];
            $chunk = substr($bytes, $offset, 8 + $size + ($size % 2));
            if ($type === 'VP8X') {
                $flags = ord($chunk[8]) & ~0x0C;
                $chunk[8] = chr($flags);
            }
            if ($type !== 'EXIF' && $type !== 'XMP ') {
                $body .= $chunk;
            }
            $offset += 8 + $size + ($size % 2);
        }

        return 'RIFF'.pack('V', strlen($body) + 4).'WEBP'.$body;
    }
}
