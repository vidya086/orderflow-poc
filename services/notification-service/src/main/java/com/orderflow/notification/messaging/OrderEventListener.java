package com.orderflow.notification.messaging;

import com.orderflow.notification.NotificationServiceApplication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class OrderEventListener {

    private static final Logger log = LoggerFactory.getLogger(OrderEventListener.class);

    @RabbitListener(queues = NotificationServiceApplication.QUEUE)
    public void onOrderCreated(Map<String, Object> event) {
        // Simulated notification. Swap this for an actual email/SMS provider
        // call once you're ready to add an outbound-network egress exercise
        // (Cloud NAT / firewall egress rules) to the roadmap.
        log.info("Sending confirmation email to {} for order {}",
                event.get("customerEmail"), event.get("orderId"));
    }
}
