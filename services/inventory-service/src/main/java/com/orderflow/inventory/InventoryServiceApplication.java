package com.orderflow.inventory;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.amqp.core.*;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class InventoryServiceApplication {

    public static final String QUEUE = "inventory.order.created";
    public static final String EXCHANGE = "order.events";
    public static final String ROUTING_KEY = "order.created";

    public static void main(String[] args) {
        SpringApplication.run(InventoryServiceApplication.class, args);
    }

    // Inventory declares its OWN queue and binds it to order-service's
    // exchange. Order-service never needs to know inventory-service exists -
    // that's the whole point of pub/sub over point-to-point HTTP calls.
    @Bean
    public Queue inventoryOrderCreatedQueue() {
        return QueueBuilder.durable(QUEUE).build();
    }

    @Bean
    public TopicExchange orderEventsExchange() {
        return new TopicExchange(EXCHANGE, true, false);
    }

    @Bean
    public Binding binding(Queue inventoryOrderCreatedQueue, TopicExchange orderEventsExchange) {
        return BindingBuilder.bind(inventoryOrderCreatedQueue).to(orderEventsExchange).with(ROUTING_KEY);
    }
}
