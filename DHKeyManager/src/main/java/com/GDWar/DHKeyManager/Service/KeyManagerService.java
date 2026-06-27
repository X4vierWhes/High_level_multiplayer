package com.GDWar.DHKeyManager.Service;

import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;

@Service
public class KeyManagerService {
    ConcurrentHashMap<String, String> keyStore = new ConcurrentHashMap<>();

    public KeyManagerService(){
        keyStore = new ConcurrentHashMap<>();
    }

    public boolean registerKey(String userId, String publicKey) {
        if (userId.isEmpty() || publicKey.isEmpty()) {
            throw new IllegalArgumentException("User ID and public key must not be empty");
        }
        keyStore.put(userId, publicKey);
        return true;
    }

    public String getKey(String userId) {
        if (userId.isEmpty()) {
            throw new IllegalArgumentException("User ID must not be empty");
        }
        return keyStore.get(userId);
    }

    public void deleteKey(String userId) {
        if (userId.isEmpty()) {
            throw new IllegalArgumentException("User ID must not be empty");
        }
        keyStore.remove(userId);
    }
}
