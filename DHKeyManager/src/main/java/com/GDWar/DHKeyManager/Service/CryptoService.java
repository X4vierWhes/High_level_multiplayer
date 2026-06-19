package com.GDWar.DHKeyManager.Service;

import org.springframework.stereotype.Service;

import java.security.*;

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
        return bytesToHex(publicKey.getEncoded());
    }

    public String signPublicKey(String message) {
        try {
            Signature privateSignature = Signature.getInstance("SHA256withRSA");
            privateSignature.initSign(privateKey);
            privateSignature.update(message.getBytes());
            return bytesToHex(privateSignature.sign());
        } catch (Exception e) {
            throw new RuntimeException("Erro ao assinar a chave pública", e);
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
}
