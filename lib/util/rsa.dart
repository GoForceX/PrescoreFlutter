import 'dart:typed_data';

import 'package:pointycastle/export.dart' hide Algorithm;
import 'package:encrypt/encrypt.dart';

/*
 * This is a helper class to encrypt and decrypt data using RSA algorithm.
 * It uses the "pointycastle" and "encrypt" library to generate the RSA keys.
 * Code from [JueJin Forum](https://juejin.cn/post/6844904133992923143)
 */

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
  })  : _publicKeyParams =
            publicKey != null ? PublicKeyParameter(publicKey) : null,
        _privateKeyParams =
            privateKey != null ? PrivateKeyParameter(privateKey) : null,
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
