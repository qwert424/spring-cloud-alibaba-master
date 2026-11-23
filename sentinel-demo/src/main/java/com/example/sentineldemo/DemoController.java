package com.example.sentineldemo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.ThreadLocalRandom;

@RestController
@RequestMapping("/api")
public class DemoController {

    private final DemoService demoService;

    public DemoController(DemoService demoService) {
        this.demoService = demoService;
    }

    @GetMapping("/hello")
    public String hello() {
        return "hello sentinel";
    }

    @GetMapping("/slow")
    public String slow() throws InterruptedException {
        Thread.sleep(300);
        return "slow ok";
    }

    @GetMapping("/error")
    public String error() {
        throw new IllegalStateException("demo error");
    }

    @GetMapping("/random")
    public String random() {
        int n = ThreadLocalRandom.current().nextInt(10);
        if (n < 3) {
            throw new IllegalStateException("random failure");
        }
        return "lucky number: " + n;
    }

    @GetMapping("/order/{id}")
    public String order(@PathVariable long id) {
        return demoService.createOrder(id);
    }
}
