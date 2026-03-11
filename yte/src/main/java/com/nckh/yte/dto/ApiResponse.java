package com.nckh.yte.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {

    private String message;
    private T data;
}
