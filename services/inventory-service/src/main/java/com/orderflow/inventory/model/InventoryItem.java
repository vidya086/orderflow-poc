package com.orderflow.inventory.model;

import jakarta.persistence.*;

@Entity
@Table(name = "inventory_items")
public class InventoryItem {

    @Id
    private String sku;

    private int quantityAvailable;

    public InventoryItem() {}

    public InventoryItem(String sku, int quantityAvailable) {
        this.sku = sku;
        this.quantityAvailable = quantityAvailable;
    }

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public int getQuantityAvailable() { return quantityAvailable; }
    public void setQuantityAvailable(int quantityAvailable) { this.quantityAvailable = quantityAvailable; }
}
