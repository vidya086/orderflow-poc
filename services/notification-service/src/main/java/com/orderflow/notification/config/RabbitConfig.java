package com.orderflow.notification.config;

import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    // Spring Boot auto-wires this into both RabbitTemplate (publish side) and
    // the default @RabbitListener container factory (consume side) once it's
    // the only MessageConverter bean present - no further config needed.
    // Replaces the default SimpleMessageConverter, which falls back to raw
    // Java serialization for non-String/byte[] payloads (like our Map) -
    // and Java deserialization is blocked by default on the consumer side
    // as a security measure (arbitrary deserialization = RCE risk). JSON
    // sidesteps that entirely, and is the sane choice for a message format
    // anyway: human-readable and not tied to the JVM.
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
