package com.example.mqdemo;

import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
@RocketMQMessageListener(topic = DemoProducer.TOPIC, consumerGroup = "demo-consumer-group")
public class DemoConsumer implements RocketMQListener<String> {

    private static final Logger log = LoggerFactory.getLogger(DemoConsumer.class);

    @Override
    public void onMessage(String message) {
        log.info("[消费成功] 收到消息: {}", message);
    }
}
