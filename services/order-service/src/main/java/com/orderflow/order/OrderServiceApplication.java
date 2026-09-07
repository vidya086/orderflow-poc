package com.orderflow.order;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.amqp.core.*;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class OrderServiceApplication {

    public static final String EXCHANGE = "order.events";
    public static final String ROUTING_KEY_CREATED = "order.created";

    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }

    // Order service owns the exchange; consumers (inventory, notification)
    // declare their own queues/bindings against it. This is the async
    // "fan-out" pattern worth understanding before you add a service mesh
    // on top of the sync (HTTP) calls.
    @Bean
    public TopicExchange orderEventsExchange() {
        return new TopicExchange(EXCHANGE, true, false);
    }
}
