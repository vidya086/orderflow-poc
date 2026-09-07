package com.orderflow.order.web;

import com.orderflow.order.messaging.OrderEventPublisher;
import com.orderflow.order.model.Order;
import com.orderflow.order.repo.OrderRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@CrossOrigin
public class OrderController {

    private final OrderRepository repository;
    private final OrderEventPublisher publisher;

    public OrderController(OrderRepository repository, OrderEventPublisher publisher) {
        this.repository = repository;
        this.publisher = publisher;
    }

    @GetMapping
    public List<Order> list() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> get(@PathVariable Long id) {
        return repository.findById(id).map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Order> create(@Valid @RequestBody Order order) {
        order.setId(null);
        Order saved = repository.save(order);
        publisher.publishOrderCreated(saved);
        return ResponseEntity.ok(saved);
    }
}
