package com.GDWar.DHKeyManager;

import com.GDWar.DHKeyManager.Service.CryptoService;
import com.GDWar.DHKeyManager.Service.KeyManagerService;
import org.apache.coyote.Response;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;

@RestController
@RequestMapping("/keymanager")
public class KeyManagerController {
    @Autowired private KeyManagerService keyManagerService;
    @Autowired private CryptoService cryptoService;

    @GetMapping()
    public String teste(){
        System.out.println("hello world!");
        return "Hello World!";
    }

    @GetMapping("/publickey")
    public String getPublicKey() {
        System.out.println("Pedido de chave pública por usuario");
        return cryptoService.getPublicKey().toString();
    }

    @GetMapping("/key/{userId}")
    public ResponseEntity<String> getKey(@PathVariable String userId) {
        String key = keyManagerService.getKey(userId);
        if (key == null) {
            System.out.println("Chave não encontrada para userId: " + userId);
            return ResponseEntity.notFound().build();
        }
        String signature = cryptoService.signPublicKey(key);
        String jsonResponse = String.format("{\"userId\": \"%s\", \"publicKey\": \"%s\", \"signature\": \"%s\"}", userId, key, signature);
        System.out.println("Chave encontrada para userId: " + userId + ", publicKey: " + key + ", signature: " + signature);
        return ResponseEntity.ok(jsonResponse);
    }

    @PostMapping("/key")
    public ResponseEntity<String> registerKey(@RequestBody HashMap<String, String> request) {
        keyManagerService.registerKey(request.get("userId"), request.get("publicKey"));
        String systemPublicKey = cryptoService.getPublicKey();
        System.out.println(systemPublicKey);
        return  ResponseEntity.ok(String.format("{\"authorityPublicKey\": \"%s\"}", systemPublicKey));
    }
}
