package com.example.sentineldemo;

import com.alibaba.csp.sentinel.annotation.SentinelResource;
import com.alibaba.csp.sentinel.slots.block.BlockException;
import org.springframework.stereotype.Service;

@Service
public class DemoService {

    @SentinelResource(value = "createOrder", blockHandler = "createOrderBlocked")
    public String createOrder(long orderId) {
        return "order created: " + orderId;
    }

    public String createOrderBlocked(long orderId, BlockException ex) {
        return "createOrder blocked by " + ex.getClass().getSimpleName();
    }
}
