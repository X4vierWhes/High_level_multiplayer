package com.GDWar.DHKeyManager.Service;

import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import java.security.*;
import java.util.Base64;

@Service
public class CryptoService {
    private PublicKey publicKey;
    private PrivateKey privateKey;

    public CryptoService() throws NoSuchAlgorithmException {
        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
        keyPairGenerator.initialize(2048);
        var keyPair = keyPairGenerator.generateKeyPair();
        publicKey = keyPair.getPublic();
        privateKey = keyPair.getPrivate();
    }

    public String getPublicKey() {
        return "-----BEGIN PUBLIC KEY-----\n" +
                Base64.getMimeEncoder(64, new byte[]{'\n'}).encodeToString(publicKey.getEncoded()) +
                "\n-----END PUBLIC KEY-----";
    }

    public String encryptMessage(String message) {
        try {
            Cipher cipher = Cipher.getInstance("RSA");
            cipher.init(Cipher.ENCRYPT_MODE, privateKey);
            byte[] encryptedBytes = cipher.doFinal(message.getBytes());
            return bytesToHex(encryptedBytes);
        } catch (Exception e) {
            throw new RuntimeException("Erro ao criptografar a mensagem", e);
        }
    }

    public String signPublicKey(String message) {
        try {
            Signature privateSignature = Signature.getInstance("SHA256withRSA");
            privateSignature.initSign(privateKey);
            privateSignature.update(message.getBytes());
//            return bytesToHex(privateSignature.sign());
            return Base64.getMimeEncoder(64, new byte[]{'\n'}).encodeToString(privateSignature.sign());
        } catch (Exception e) {
            throw new RuntimeException("Erro ao assinar a chave pública", e);
        }
    }

    public boolean verifySignature(String message, String signature) {
        try {
            Signature publicSignature = Signature.getInstance("SHA256withRSA");
            publicSignature.initVerify(publicKey);
            publicSignature.update(message.getBytes());
            byte[] signatureBytes = hexStringToByteArray(signature);
            return publicSignature.verify(signatureBytes);
        } catch (Exception e) {
            throw new RuntimeException("Erro ao verificar a assinatura", e);
        }
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder hexString = new StringBuilder();
        for (byte b : bytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }
        return hexString.toString();
    }

    private byte[] hexStringToByteArray(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                                 + Character.digit(s.charAt(i+1), 16));
        }
        return data;
    }
}
