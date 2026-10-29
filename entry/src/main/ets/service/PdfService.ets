import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';

class ByteBuilder {
  private chunks: Uint8Array[] = [];
  private total: number = 0;

  pushAscii(text: string): void {
    const bytes: Uint8Array = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i++) {
      bytes[i] = text.charCodeAt(i) & 0xFF;
    }
    this.pushBytes(bytes);
  }

  pushBytes(bytes: Uint8Array): void {
    this.chunks.push(bytes);
    this.total += bytes.length;
  }

  length(): number {
    return this.total;
  }

  toBytes(): Uint8Array {
    const out: Uint8Array = new Uint8Array(this.total);
    let offset: number = 0;
    for (let i = 0; i < this.chunks.length; i++) {
      out.set(this.chunks[i], offset);
      offset += this.chunks[i].length;
    }
    return out;
  }
}

/**
 * 将简历长图封装成单页 PDF：页面尺寸按图片比例自适应，避免分页截断内容。
 * 采用 DCTDecode 直接嵌入 JPEG，无需字体，彻底规避中文乱码。
 */
export class PdfService {
  private static pad(value: number, len: number): string {
    let text: string = value.toString();
    while (text.length < len) {
      text = '0' + text;
    }
    return text;
  }

  static async build(pixelMap: image.PixelMap): Promise<Uint8Array> {
    const info: image.ImageInfo = await pixelMap.getImageInfo();
    const width: number = info.size.width;
    const height: number = info.size.height;
    const packer: image.ImagePacker = image.createImagePacker();
    let jpegBuffer: ArrayBuffer;
    try {
      jpegBuffer = await packer.packing(pixelMap, { format: 'image/jpeg', quality: 92 });
    } finally {
      packer.release();
    }
    const jpeg: Uint8Array = new Uint8Array(jpegBuffer);

    const pageW: number = 595.28;
    const pageH: number = pageW * height / width;
    const pageWText: string = pageW.toFixed(2);
    const pageHText: string = pageH.toFixed(2);

    const out: ByteBuilder = new ByteBuilder();
    const offsets: number[] = [0, 0, 0, 0, 0, 0];

    out.pushAscii('%PDF-1.4\n');

    offsets[1] = out.length();
    out.pushAscii('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    offsets[2] = out.length();
    out.pushAscii('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    offsets[3] = out.length();
    out.pushAscii('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ' + pageWText + ' ' +
      pageHText + '] /Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>\nendobj\n');

    offsets[4] = out.length();
    out.pushAscii('4 0 obj\n<< /Type /XObject /Subtype /Image /Width ' + width.toString() +
      ' /Height ' + height.toString() +
      ' /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ' +
      jpeg.length.toString() + ' >>\nstream\n');
    out.pushBytes(jpeg);
    out.pushAscii('\nendstream\nendobj\n');

    const content: string = 'q\n' + pageWText + ' 0 0 ' + pageHText + ' 0 0 cm\n/Im0 Do\nQ\n';
    offsets[5] = out.length();
    out.pushAscii('5 0 obj\n<< /Length ' + content.length.toString() + ' >>\nstream\n' +
      content + 'endstream\nendobj\n');

    const xrefOffset: number = out.length();
    out.pushAscii('xref\n0 6\n');
    out.pushAscii('0000000000 65535 f \n');
    for (let i = 1; i < 6; i++) {
      out.pushAscii(PdfService.pad(offsets[i], 10) + ' 00000 n \n');
    }
    out.pushAscii('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n' +
      xrefOffset.toString() + '\n%%EOF\n');

    return out.toBytes();
  }

  static write(uri: string, bytes: Uint8Array): void {
    const file = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    try {
      const buffer: ArrayBuffer = new ArrayBuffer(bytes.length);
      new Uint8Array(buffer).set(bytes);
      fs.writeSync(file.fd, buffer);
    } finally {
      fs.closeSync(file);
    }
  }
}
