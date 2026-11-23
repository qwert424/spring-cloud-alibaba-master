package com.example.mqdemo;

import org.apache.rocketmq.client.producer.SendResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DemoController {

    private final DemoProducer demoProducer;

    public DemoController(DemoProducer demoProducer) {
        this.demoProducer = demoProducer;
    }

    @GetMapping("/send")
    public String send(@RequestParam(defaultValue = "hello rocketmq") String msg) {
        SendResult result = demoProducer.send(msg);
        return result.getSendStatus() + ", msgId=" + result.getMsgId();
    }
}
