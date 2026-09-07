package com.orderflow.inventory.web;

import com.orderflow.inventory.model.InventoryItem;
import com.orderflow.inventory.repo.InventoryRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/inventory")
@CrossOrigin
public class InventoryController {

    private final InventoryRepository repository;

    public InventoryController(InventoryRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<InventoryItem> list() {
        return repository.findAll();
    }

    @PostMapping
    public InventoryItem upsert(@RequestBody InventoryItem item) {
        return repository.save(item);
    }
}
