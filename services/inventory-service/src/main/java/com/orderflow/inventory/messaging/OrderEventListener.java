package com.orderflow.inventory.messaging;

import com.orderflow.inventory.InventoryServiceApplication;
import com.orderflow.inventory.model.InventoryItem;
import com.orderflow.inventory.repo.InventoryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;

@Component
public class OrderEventListener {

    private static final Logger log = LoggerFactory.getLogger(OrderEventListener.class);
    private final InventoryRepository repository;

    public OrderEventListener(InventoryRepository repository) {
        this.repository = repository;
    }

    @RabbitListener(queues = InventoryServiceApplication.QUEUE)
    public void onOrderCreated(Map<String, Object> event) {
        String sku = (String) event.get("sku");
        Integer quantity = (Integer) event.get("quantity");
        log.info("Received order.created for sku={} qty={}", sku, quantity);

        Optional<InventoryItem> maybeItem = repository.findById(sku);
        if (maybeItem.isEmpty()) {
            log.warn("Unknown sku {} - nothing to reserve", sku);
            return;
        }
        InventoryItem item = maybeItem.get();
        int remaining = item.getQuantityAvailable() - quantity;
        item.setQuantityAvailable(Math.max(remaining, 0));
        repository.save(item);
        log.info("Updated stock for {}: {} remaining", sku, item.getQuantityAvailable());
    }
}
