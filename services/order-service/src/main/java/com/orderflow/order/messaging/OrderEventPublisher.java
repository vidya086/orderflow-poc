package com.orderflow.order.messaging;

import com.orderflow.order.OrderServiceApplication;
import com.orderflow.order.model.Order;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class OrderEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    public OrderEventPublisher(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishOrderCreated(Order order) {
        Map<String, Object> event = Map.of(
                "orderId", order.getId(),
                "sku", order.getSku(),
                "quantity", order.getQuantity(),
                "customerEmail", order.getCustomerEmail()
        );
        rabbitTemplate.convertAndSend(
                OrderServiceApplication.EXCHANGE,
                OrderServiceApplication.ROUTING_KEY_CREATED,
                event
        );
    }
}
