package com.nckh.yte.controller;

import com.nckh.yte.service.NurseService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin("*")
public class AdminNurseController {

    private final NurseService service;

    public AdminNurseController(NurseService service){
        this.service = service;
    }

}
