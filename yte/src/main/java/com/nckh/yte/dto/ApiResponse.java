package com.nckh.yte.dto;

public class ApiResponse<T> {

    private String message;
    private T data;

    // Constructor mặc định
    public ApiResponse() {
    }

    // Constructor với message và data
    public ApiResponse(String message, T data) {
        this.message = message;
        this.data = data;
    }

    // Getter và Setter cho message
    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    // Getter và Setter cho data
    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }
}
