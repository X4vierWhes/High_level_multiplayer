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
        return "Hello World!";
    }

    @GetMapping("/publickey")
    public String getPublicKey() {
        return cryptoService.getPublicKey().toString();
    }

    @GetMapping("/key/{userId}")
    public ResponseEntity<String> getKey(@PathVariable String userId) {
        String key = keyManagerService.getKey(userId);
        if (key == null) {
            return ResponseEntity.notFound().build();
        }
        String signature = cryptoService.signPublicKey(key);
        String jsonResponse = String.format("{\"userId: \"%s\", \"publicKey\": \"%s\", \"signature\": \"%s\"}", userId, key, signature);
        return ResponseEntity.ok(jsonResponse);
    }

    @PostMapping("/key")
    public HttpStatus registerKey(@RequestBody HashMap<String, String> request) {
        System.out.println("Registering key for userId: " + request.get("userId") + ", publicKey: " + request.get("publicKey"));
        return keyManagerService.registerKey(request.get("userId"), request.get("publicKey")) ? HttpStatus.CREATED : HttpStatus.CONFLICT;
    }
}
