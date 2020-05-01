import 'dart:typed_data';

import 'package:image/image.dart';

class JpegHider extends JpegEncoder {
  Uint8List msgBytes = Uint8List.fromList('message'.codeUnits);
  int iByte = 0;
  int iBit = 7;

  JpegHider() : super();

  List<int> hideMessage(Image img) {
    OutputBuffer fp = OutputBuffer(bigEndian: true);

    // Add JPEG headers
    _writeMarker(fp, Jpeg.M_SOI);
    _writeAPP0(fp);
    _writeAPP1(fp, img);
    _writeDQT(fp);
    _writeSOF0(fp, img.width, img.height);
    _writeDHT(fp);
    _writeSOS(fp);

    // Encode 8x8 macroblocks
    int DCY = 0;
    int DCU = 0;
    int DCV = 0;

    _resetBits();

    int width = img.width;
    int height = img.height;

    Uint8List imageData = img.getBytes();
    int quadWidth = width * 4;
    //int tripleWidth = width * 3;
    //bool first = true;

    int y = 0;
    while (y < height) {
      int x = 0;
      while (x < quadWidth) {
        int start = quadWidth * y + x;
        for (int pos = 0; pos < 64; pos++) {
          int row = pos >> 3; // / 8
          int col = (pos & 7) * 4; // % 8
          int p = start + (row * quadWidth) + col;

          if (y + row >= height) { // padding bottom
            p -= (quadWidth * (y + 1 + row - height));
          }

          if (x + col >= quadWidth) { // padding right
            p -= ((x + col) - quadWidth + 4);
          }

          int r = imageData[p++];
          int g = imageData[p++];
          int b = imageData[p++];

          // calculate YUV values
          YDU[pos] = ((RGB_YUV_TABLE[r] +
              RGB_YUV_TABLE[(g +  256)] +
              RGB_YUV_TABLE[(b +  512)]) >> 16) - 128.0;

          UDU[pos] = ((RGB_YUV_TABLE[(r +  768)] +
              RGB_YUV_TABLE[(g + 1024)] +
              RGB_YUV_TABLE[(b + 1280)]) >> 16) - 128.0;

          VDU[pos] = ((RGB_YUV_TABLE[(r + 1280)] +
              RGB_YUV_TABLE[(g + 1536)] +
              RGB_YUV_TABLE[(b + 1792)]) >> 16) - 128.0;
        }

        DCY = _processDUAndHide(fp, YDU, fdtbl_Y, DCY, YDC_HT, YAC_HT);
        DCU = _processDUAndHide(fp, UDU, fdtbl_UV, DCU, UVDC_HT, UVAC_HT);
        DCV = _processDUAndHide(fp, VDU, fdtbl_UV, DCV, UVDC_HT, UVAC_HT);

        x += 32;
      }

      y += 8;
    }

    ////////////////////////////////////////////////////////////////

    // Do the bit alignment of the EOI marker
    if (_bytepos >= 0) {
      final fillBits = [(1 << (_bytepos + 1)) - 1, _bytepos + 1];
      _writeBits(fp, fillBits);
    }

    _writeMarker(fp, Jpeg.M_EOI);

    return fp.getBytes();
  }

  int _processDUAndHide(OutputBuffer out, List<double> CDU, List<double> fdtbl,
      int DC, List<List<int>> HTDC, List<List<int>> HTAC) {
    List<int> EOB = HTAC[0x00];
    List<int> M16zeroes = HTAC[0xF0];
    int pos;
    const I16 = 16;
    const I63 = 63;
    const I64 = 64;
    List<int> DU_DCT = _fDCTQuant(CDU, fdtbl);

    // Hide message bits in one coef per block
    if (iByte < msgBytes.length) {
      int bit = (msgBytes[iByte] >> iBit) & 1;
      iBit--;
      if (iBit == -1) {
        iBit = 7;
        iByte++;
      }
      int coef = DU_DCT[2];
      bool neg = coef < 0;
      coef = (neg ? -coef : coef) & 0xfffffffe | bit;
      DU_DCT[2] = neg ? -coef : coef;
    }

    // ZigZag reorder
    for (int j = 0; j < I64; ++j) {
      DU[JpegEncoder.ZIGZAG[j]] = DU_DCT[j];
    }

    int Diff = DU[0] - DC;
    DC = DU[0];
    // Encode DC
    if (Diff == 0) {
      _writeBits(out, HTDC[0]); // Diff might be 0
    } else {
      pos = 32767 + Diff;
      _writeBits(out, HTDC[category[pos]]);
      _writeBits(out, bitcode[pos]);
    }

    // Encode ACs
    int end0pos = 63;
    for (; (end0pos > 0) && (DU[end0pos] == 0); end0pos--) {};
    //end0pos = first element in reverse order !=0
    if ( end0pos == 0) {
      _writeBits(out, EOB);
      return DC;
    }

    int i = 1;
    int lng;
    while (i <= end0pos) {
      int startpos = i;
      for (; (DU[i] == 0) && (i <= end0pos); ++i) {
      }

      int nrzeroes = i - startpos;
      if (nrzeroes >= I16) {
        lng = nrzeroes >> 4;
        for (int nrmarker = 1; nrmarker <= lng; ++nrmarker) {
          _writeBits(out, M16zeroes);
        }
        nrzeroes = nrzeroes & 0xF;
      }
      pos = 32767 + DU[i];
      _writeBits(out, HTAC[(nrzeroes << 4) + category[pos]]);
      _writeBits(out, bitcode[pos]);
      i++;
    }

    if (end0pos != I63) {
      _writeBits(out, EOB);
    }

    return DC;
  }

  void _writeMarker(OutputBuffer fp, int marker) {
    fp.writeByte(0xff);
    fp.writeByte(marker & 0xff);
  }

  // DCT & quantization core
  List<int> _fDCTQuant(List<double> data, List<double> fdtbl) {
    // Pass 1: process rows.
    int dataOff = 0;
    const I8 = 8;
    const I64 = 64;
    for (int i = 0; i < I8; ++i) {
      double d0 = data[dataOff];
      double d1 = data[dataOff + 1];
      double d2 = data[dataOff + 2];
      double d3 = data[dataOff + 3];
      double d4 = data[dataOff + 4];
      double d5 = data[dataOff + 5];
      double d6 = data[dataOff + 6];
      double d7 = data[dataOff + 7];

      double tmp0 = d0 + d7;
      double tmp7 = d0 - d7;
      double tmp1 = d1 + d6;
      double tmp6 = d1 - d6;
      double tmp2 = d2 + d5;
      double tmp5 = d2 - d5;
      double tmp3 = d3 + d4;
      double tmp4 = d3 - d4;

      // Even part
      double tmp10 = tmp0 + tmp3; // phase 2
      double tmp13 = tmp0 - tmp3;
      double tmp11 = tmp1 + tmp2;
      double tmp12 = tmp1 - tmp2;

      data[dataOff] = tmp10 + tmp11; // phase 3
      data[dataOff + 4] = tmp10 - tmp11;

      double z1 = (tmp12 + tmp13) * 0.707106781; // c4
      data[dataOff + 2] = tmp13 + z1; // phase 5
      data[dataOff + 6] = tmp13 - z1;

      // Odd part
      tmp10 = tmp4 + tmp5; // phase 2
      tmp11 = tmp5 + tmp6;
      tmp12 = tmp6 + tmp7;

      // The rotator is modified from fig 4-8 to avoid extra negations.
      double z5 = (tmp10 - tmp12) * 0.382683433; // c6
      double z2 = 0.541196100 * tmp10 + z5; // c2 - c6
      double z4 = 1.306562965 * tmp12 + z5; // c2 + c6
      double z3 = tmp11 * 0.707106781; // c4

      double z11 = tmp7 + z3; // phase 5
      double z13 = tmp7 - z3;

      data[dataOff + 5] = z13 + z2; // phase 6
      data[dataOff + 3] = z13 - z2;
      data[dataOff + 1] = z11 + z4;
      data[dataOff + 7] = z11 - z4;

      dataOff += 8; // advance pointer to next row
    }

    // Pass 2: process columns.
    dataOff = 0;
    for (int i = 0; i < I8; ++i) {
      double d0 = data[dataOff];
      double d1 = data[dataOff + 8];
      double d2 = data[dataOff + 16];
      double d3 = data[dataOff + 24];
      double d4 = data[dataOff + 32];
      double d5 = data[dataOff + 40];
      double d6 = data[dataOff + 48];
      double d7 = data[dataOff + 56];

      double tmp0p2 = d0 + d7;
      double tmp7p2 = d0 - d7;
      double tmp1p2 = d1 + d6;
      double tmp6p2 = d1 - d6;
      double tmp2p2 = d2 + d5;
      double tmp5p2 = d2 - d5;
      double tmp3p2 = d3 + d4;
      double tmp4p2 = d3 - d4;

      // Even part
      double tmp10p2 = tmp0p2 + tmp3p2;        // phase 2
      double tmp13p2 = tmp0p2 - tmp3p2;
      double tmp11p2 = tmp1p2 + tmp2p2;
      double tmp12p2 = tmp1p2 - tmp2p2;

      data[dataOff] = tmp10p2 + tmp11p2; // phase 3
      data[dataOff + 32] = tmp10p2 - tmp11p2;

      double z1p2 = (tmp12p2 + tmp13p2) * 0.707106781; // c4
      data[dataOff + 16] = tmp13p2 + z1p2; // phase 5
      data[dataOff + 48] = tmp13p2 - z1p2;

      // Odd part
      tmp10p2 = tmp4p2 + tmp5p2; // phase 2
      tmp11p2 = tmp5p2 + tmp6p2;
      tmp12p2 = tmp6p2 + tmp7p2;

      // The rotator is modified from fig 4-8 to avoid extra negations.
      double z5p2 = (tmp10p2 - tmp12p2) * 0.382683433; // c6
      double z2p2 = 0.541196100 * tmp10p2 + z5p2; // c2 - c6
      double z4p2 = 1.306562965 * tmp12p2 + z5p2; // c2 + c6
      double z3p2 = tmp11p2 * 0.707106781; // c4

      double z11p2 = tmp7p2 + z3p2;        // phase 5
      double z13p2 = tmp7p2 - z3p2;

      data[dataOff + 40] = z13p2 + z2p2; // phase 6
      data[dataOff + 24] = z13p2 - z2p2;
      data[dataOff + 8] = z11p2 + z4p2;
      data[dataOff + 56] = z11p2 - z4p2;

      dataOff++; // advance pointer to next column
    }

    // Quantize/descale the coefficients
    for (int i = 0; i < I64; ++i) {
      // Apply the quantization and scaling factor & Round to nearest integer
      double fDCTQuant = data[i] * fdtbl[i];
      outputfDCTQuant[i] = (fDCTQuant > 0.0) ?
      ((fDCTQuant + 0.5).toInt()) :
      ((fDCTQuant - 0.5).toInt());
    }

    return outputfDCTQuant;
  }

  void _writeAPP0(OutputBuffer out) {
    _writeMarker(out, Jpeg.M_APP0);
    out.writeUint16(16); // length
    out.writeByte(0x4A); // J
    out.writeByte(0x46); // F
    out.writeByte(0x49); // I
    out.writeByte(0x46); // F
    out.writeByte(0); // '\0'
    out.writeByte(1); // versionhi
    out.writeByte(1); // versionlo
    out.writeByte(0); // xyunits
    out.writeUint16(1); // xdensity
    out.writeUint16(1); // ydensity
    out.writeByte(0); // thumbnwidth
    out.writeByte(0); // thumbnheight
  }

  void _writeAPP1(OutputBuffer out, Image img) {
    if (img.exif.rawData == null) {
      return;
    }

    for (var rawData in img.exif.rawData) {
      _writeMarker(out, Jpeg.M_APP1);
      out.writeUint16(rawData.length + 2);
      out.writeBytes(rawData);
    }
  }

  void _writeSOF0(OutputBuffer out, int width, int height) {
    _writeMarker(out, Jpeg.M_SOF0);
    out.writeUint16(17); // length, truecolor YUV JPG
    out.writeByte(8); // precision
    out.writeUint16(height);
    out.writeUint16(width);
    out.writeByte(3); // nrofcomponents
    out.writeByte(1); // IdY
    out.writeByte(0x11); // HVY
    out.writeByte(0); // QTY
    out.writeByte(2); // IdU
    out.writeByte(0x11); // HVU
    out.writeByte(1); // QTU
    out.writeByte(3); // IdV
    out.writeByte(0x11); // HVV
    out.writeByte(1); // QTV
  }

  void _writeDQT(OutputBuffer out) {
    _writeMarker(out, Jpeg.M_DQT);
    out.writeUint16(132); // length
    out.writeByte(0);
    for (int i = 0; i < 64; i++) {
      out.writeByte(YTable[i]);
    }
    out.writeByte(1);
    for (int j = 0; j < 64; j++) {
      out.writeByte(UVTable[j]);
    }
  }

  void _writeDHT(OutputBuffer out) {
    _writeMarker(out, Jpeg.M_DHT);
    out.writeUint16(0x01A2); // length

    out.writeByte(0); // HTYDCinfo
    for (int i = 0; i < 16; i++) {
      out.writeByte(JpegEncoder.STD_DC_LUMINANCE_NR_CODES[i + 1]);
    }
    for (int j = 0; j <= 11; j++) {
      out.writeByte(JpegEncoder.STD_DC_LUMINANCE_VALUES[j]);
    }

    out.writeByte(0x10); // HTYACinfo
    for (int k = 0; k < 16; k++) {
      out.writeByte(JpegEncoder.STD_AC_LUMINANCE_NR_CODES[k + 1]);
    }
    for (int l = 0; l <= 161; l++) {
      out.writeByte(JpegEncoder.STD_AC_LUMINANCE_VALUES[l]);
    }

    out.writeByte(1); // HTUDCinfo
    for (int m = 0; m < 16; m++) {
      out.writeByte(JpegEncoder.STD_DC_CHROMINANCE_NR_CODES[m + 1]);
    }
    for (int n = 0; n <= 11; n++) {
      out.writeByte(JpegEncoder.STD_DC_CHROMINANCE_VALUES[n]);
    }

    out.writeByte(0x11); // HTUACinfo
    for (int o = 0; o < 16; o++) {
      out.writeByte(JpegEncoder.STD_AC_CHROMINANCE_NR_CODES[o + 1]);
    }
    for (int p = 0; p <= 161; p++) {
      out.writeByte(JpegEncoder.STD_AC_CHROMINANCE_VALUES[p]);
    }
  }

  void _writeSOS(OutputBuffer out) {
    _writeMarker(out, Jpeg.M_SOS);
    out.writeUint16(12); // length
    out.writeByte(3); // nrofcomponents
    out.writeByte(1); // IdY
    out.writeByte(0); // HTY
    out.writeByte(2); // IdU
    out.writeByte(0x11); // HTU
    out.writeByte(3); // IdV
    out.writeByte(0x11); // HTV
    out.writeByte(0); // Ss
    out.writeByte(0x3f); // Se
    out.writeByte(0); // Bf
  }

  void _writeBits(OutputBuffer out, List<int> bits) {
    int value = bits[0];
    int posval = bits[1] - 1;
    while (posval >= 0) {
      if ((value & (1 << posval)) != 0) {
        _bytenew |= (1 << _bytepos);
      }
      posval--;
      _bytepos--;
      if (_bytepos < 0) {
        if (_bytenew == 0xff) {
          out.writeByte(0xff);
          out.writeByte(0);
        } else {
          out.writeByte(_bytenew);
        }
        _bytepos = 7;
        _bytenew = 0;
      }
    }
  }

  void _resetBits() {
    _bytenew = 0;
    _bytepos = 7;
  }

  int _bytenew = 0;
  int _bytepos = 7;
}
