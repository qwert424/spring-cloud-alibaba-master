package com.example.mqdemo;

import org.apache.rocketmq.client.producer.SendResult;
import org.apache.rocketmq.spring.core.RocketMQTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.time.LocalTime;

@Component
public class DemoProducer implements ApplicationRunner {

    public static final String TOPIC = "demo-topic";

    private static final Logger log = LoggerFactory.getLogger(DemoProducer.class);

    private final RocketMQTemplate rocketMQTemplate;

    public DemoProducer(RocketMQTemplate rocketMQTemplate) {
        this.rocketMQTemplate = rocketMQTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        send("应用启动后的第一条消息");
    }

    public SendResult send(String text) {
        String payload = text + " | " + LocalTime.now().withNano(0);
        SendResult result = rocketMQTemplate.syncSend(TOPIC, payload);
        log.info("[发送成功] status={}, msgId={}, body={}", result.getSendStatus(), result.getMsgId(), payload);
        return result;
    }
}
