import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' hide Algorithm;
import 'package:encrypt/encrypt.dart';

BigInt readBytes(List<int> bytes) {
  BigInt read(int start, int end) {
    if (end - start <= 4) {
      int result = 0;
      for (int i = end - 1; i >= start; i--) {
        result = result * 256 + bytes[i];
      }
      return BigInt.from(result);
    }
    int mid = start + ((end - start) >> 1);
    var result =
        read(start, mid) + read(mid, end) * (BigInt.one << ((mid - start) * 8));
    return result;
  }

  return read(0, bytes.length);
}

List<int> writeBigInt(BigInt number) {
  // Not handling negative numbers. Decide how you want to do that.
  int bytes = (number.bitLength + 7) >> 3;
  var b256 = BigInt.from(256);
  var result = List<int>.generate(bytes, (index) => 0);
  for (int i = 0; i < bytes; i++) {
    result[i] = number.remainder(b256).toInt();
    number = number >> 8;
  }
  return result;
}

Future<String> rsaEncrypt(String message) async {
  BigInt payload = readBytes(utf8.encode(message));
  int ekey = 65537;
  BigInt n = BigInt.parse("0x008c147f73c2593cba0bd007e60a89ade5");

  BigInt encrypted = payload.pow(ekey);
  encrypted = encrypted % n;

  return encrypted.toRadixString(16);
}

class NoPaddingEncoding extends PKCS1Encoding {
  NoPaddingEncoding(this._engine) : super(_engine);

  final AsymmetricBlockCipher _engine;

  late int _keyLength;
  late bool _forEncryption;

  @override
  void init(bool forEncryption, CipherParameters params) {
    super.init(forEncryption, params);
    _forEncryption = forEncryption;
    if (params is AsymmetricKeyParameter<RSAAsymmetricKey> &&
        params.key.modulus != null) {
      _keyLength = (params.key.modulus!.bitLength + 7) ~/ 8;
    }
  }

  @override
  int get inputBlockSize {
    return _keyLength;
  }

  @override
  int get outputBlockSize {
    return _keyLength;
  }

  @override
  int processBlock(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    if (_forEncryption) {
      return _encodeBlock(inp, inpOff, len, out, outOff);
    } else {
      return _decodeBlock(inp, inpOff, len, out, outOff);
    }
  }

  int _encodeBlock(
      Uint8List inp, int inpOff, int inpLen, Uint8List out, int outOff) {
    if (inpLen > inputBlockSize) {
      throw ArgumentError("Input data too large");
    }

    var block = Uint8List(inputBlockSize);
    var padLength = (block.length - inpLen);

    // 补0
    block.fillRange(0, padLength, 0x00);

    block.setRange(padLength, block.length, inp.sublist(inpOff));

    return _engine.processBlock(block, 0, block.length, out, outOff);
  }

  int _decodeBlock(
      Uint8List inp, int inpOff, int inpLen, Uint8List out, int outOff) {
    var block = Uint8List(outputBlockSize);
    var len = _engine.processBlock(inp, inpOff, inpLen, block, 0);
    block = block.sublist(0, len);

    if (block.length < outputBlockSize) {
      throw ArgumentError("Block truncated");
    }

    return block.length;
  }
}

abstract class AbstractRSAExt {
  final RSAPublicKey? publicKey;
  final RSAPrivateKey? privateKey;
  final PublicKeyParameter<RSAPublicKey>? _publicKeyParams;
  final PrivateKeyParameter<RSAPrivateKey>? _privateKeyParams;
  final AsymmetricBlockCipher _cipher;

  AbstractRSAExt({
    this.publicKey,
    this.privateKey,
  })  : _publicKeyParams = publicKey != null ? PublicKeyParameter(publicKey) : null,
        _privateKeyParams = privateKey != null ? PrivateKeyParameter(privateKey) : null,
        _cipher = NoPaddingEncoding(RSAEngine());
}

class RSAExt extends AbstractRSAExt implements Algorithm {
  RSAExt({RSAPublicKey? publicKey, required RSAPrivateKey? privateKey})
      : super(publicKey: publicKey, privateKey: privateKey);

  @override
  Encrypted encrypt(Uint8List bytes, {IV? iv}) {
    if (publicKey == null || _publicKeyParams == null) {
      throw StateError('Can\'t encrypt without a public key, null given.');
    }

    _cipher
      ..reset()
      ..init(true, _publicKeyParams!);

    return Encrypted(_cipher.process(bytes));
  }

  @override
  Uint8List decrypt(Encrypted encrypted, {IV? iv}) {
    if (privateKey == null || _privateKeyParams == null) {
      throw StateError('Can\'t decrypt without a private key, null given.');
    }

    _cipher
      ..reset()
      ..init(false, _privateKeyParams!);

    return _cipher.process(encrypted.bytes);
  }
}
