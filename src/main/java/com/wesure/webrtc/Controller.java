package com.wesure.webrtc;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

@RestController
public class Controller {

	@RequestMapping(value = "/", method = RequestMethod.GET)
	public ModelAndView index(Model model, HttpSession session, HttpServletRequest request,
			HttpServletResponse response)  {
		
		String usrType = request.getParameter("usrType");
		
		model.addAttribute("usrType", usrType);
		return new ModelAndView("webRTC");
	}
	
	@RequestMapping(value = "/test/", method = RequestMethod.GET)
	public ModelAndView test(Model model, HttpSession session, HttpServletRequest request,
			HttpServletResponse response)  {
		
		String usrType = request.getParameter("usrType");
		System.out.println(usrType+"<>---usrType");
		//model.addAttribute(usrType);
		model.addAttribute("usrType", usrType);
		model.addAttribute("testID", "test Value");
		return new ModelAndView("test");
	}
}
