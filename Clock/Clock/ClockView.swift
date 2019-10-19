//
//  ClockView.swift
//  Clock
//
//  Created by Ben Gohlke on 6/24/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

struct Hand {
    let width: CGFloat // in points
    // length is proportionate to size of view, so the higher the number,
    // the shorter the hand length
    let length: CGFloat
    let color: UIColor
    // 1-12 for hour, 0-60 for minutes/seconds
    var value: Int = 0
}

@IBDesignable
class ClockView: UIView {
    
    // MARK: - Properties
    
    // Used to sync timing of animation events to the refresh rate of the display
    private var animationTimer: CADisplayLink?
    
    /// Tracks the current timezone of the clock.
    /// Automatically configures the timer to run in sync with the screen
    /// and update the face each second.
    var timezone: TimeZone? {
        didSet {
            let aTimer = CADisplayLink(target: self, selector: #selector(timerFired(_:)))
            aTimer.preferredFramesPerSecond = 1
            aTimer.add(to: .current, forMode: .common)
            animationTimer = aTimer
        }
    }
    
    private var seconds = Hand(width: 1.5, length: 2.4, color: .red, value: 34)
    private var minutes = Hand(width: 4.5, length: 3.2, color: .black, value: 14)
    private var hours = Hand(width: 6.0, length: 4.6, color: .black, value: 4)
    
    private var secondHandEndPoint: CGPoint {
        let secondsAsRadians = Float(Double(seconds.value) / 60.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / seconds.length)
        return handEndPoint(with: secondsAsRadians, and: handLength)
    }
    
    private var minuteHandEndPoint: CGPoint {
        let minutesAsRadians = Float(Double(minutes.value) / 60.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / minutes.length)
        return handEndPoint(with: minutesAsRadians, and: handLength)
    }
    
    private var hourHandEndPoint: CGPoint {
        let totalHours = Double(hours.value) + Double(minutes.value) / 60.0
        let hoursAsRadians = Float(totalHours / 12.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / hours.length)
        return handEndPoint(with: hoursAsRadians, and: handLength)
    }
    
    private let clockBgColor = UIColor.white
    
    private let borderColor = UIColor.black
    private let borderWidth: CGFloat = 8.0
    
    private let digitColor = UIColor.black
    private let digitOffset: CGFloat = 15.0
    private var digitFont: UIFont {
        return UIFont.systemFont(ofSize: 12.0 + frame.size.width / 50.0)
    }
    
    // MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        /// Note: elements are drawn on the the screen from back to front
        /// in the order they appear below.
        
        if let context = UIGraphicsGetCurrentContext() {
            // red rect
//            context.addRect(rect)
//            context.setFillColor(UIColor.red.cgColor)
//            context.fillPath()
            //            context.fill(rect)
            
            // blue ring
//            context.addEllipse(in: rect)
//            context.setStrokeColor(UIColor.blue.cgColor)
//            context.setLineWidth(4)
//            context.strokePath()
            
            // clock face
            context.addEllipse(in: rect)
            context.setFillColor(clockBgColor.cgColor)
            context.fillPath()
            // clock's border
            
            let borderRect = CGRect(x: 0 + borderWidth / 2,
                                    y: 0 + borderWidth / 2,
                                    width: rect.width - borderWidth,
                                    height: rect.height - borderWidth)
            context.addEllipse(in: borderRect)
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth)
            context.strokePath()
            
            
            // numerals
            let clockCenter = CGPoint(x: rect.size.width / 2.0,
                                      y: rect.size.height / 2.0)
            let numeralDistanceFromCenter = rect.size.width / 2.0 - digitFont.lineHeight / 4.0 - digitOffset
            let offset = 3 // offsets numerals, putting "12" at the top of the clock

            for i in 1...12 {
                let hourString: NSString
                if i < 10 {
                    hourString = " \(i)" as NSString
                } else {
                    hourString = "\(i)" as NSString
                }
                let labelX = clockCenter.x + (numeralDistanceFromCenter - digitFont.lineHeight / 2.0)
                    * CGFloat(cos((Double.pi / 180) * Double(i + offset) * 30 + Double.pi))
                let labelY = clockCenter.y - 1 * (numeralDistanceFromCenter - digitFont.lineHeight / 2.0)
                    * CGFloat(sin((Double.pi / 180) * Double(i + offset) * 30))
                hourString.draw(in: CGRect(x: labelX - digitFont.lineHeight / 2.0,
                                           y: labelY - digitFont.lineHeight / 2.0,
                                           width: digitFont.lineHeight,
                                           height: digitFont.lineHeight),
                                withAttributes: [NSAttributedString.Key.foregroundColor: digitColor,
                                                 NSAttributedString.Key.font: digitFont])
            }
            
            // Drawing a String
            let brand = NSString(string: "Chance Payne")
            let brandFont = UIFont.italicSystemFont(ofSize: 10.0 + frame.size.width / 50.0)
            let brandWidth: Double = 12 * Double(brand.length)
            let centerRect = CGRect(x: Double(clockCenter.x) - brandWidth / 2.0 + 4.0, y: Double(clockCenter.y) * 1.5, width: brandWidth, height: Double(brandFont.lineHeight))
            brand.draw(in: centerRect, withAttributes: [
                NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                NSAttributedString.Key.font: brandFont
            ])
            
            // minute hand
            context.move(to: clockCenter)
            context.addLine(to: minuteHandEndPoint)
            context.setLineWidth(minutes.width)
            context.setStrokeColor(minutes.color.cgColor)
            context.strokePath()
            
            // hour hand
            context.move(to: clockCenter)
            context.addLine(to: hourHandEndPoint)
            context.setLineWidth(hours.width)
            context.setStrokeColor(hours.color.cgColor)
            context.strokePath()

            // hour/minute's center
            let hourDiam = hours.width * 2
            let hourMinCenterRect = CGRect(x: clockCenter.x - hourDiam / 2.0, y: clockCenter.y - hourDiam / 2.0, width: hourDiam, height: hourDiam)
            context.addEllipse(in: hourMinCenterRect)
            context.setFillColor(hours.color.cgColor)
            context.fillPath()
            
            // second hand
            context.move(to: clockCenter)
            context.addLine(to: secondHandEndPoint)
            context.setLineWidth(seconds.width)
            context.setStrokeColor(seconds.color.cgColor)
            context.strokePath()

            // second's center
            let secondsDiam = seconds.width * 2
            let secondsCenterRect = CGRect(x: clockCenter.x - secondsDiam / 2.0, y: clockCenter.y - secondsDiam / 2.0, width: secondsDiam, height: secondsDiam)
            context.addEllipse(in: secondsCenterRect)
            context.setFillColor(seconds.color.cgColor)
            context.fillPath()
        }
    }
    
    @objc func timerFired(_ sender: CADisplayLink) {
        // Get current time
        let currentTime = Date()
        
        // Get calendar and set timezone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone!
        
        // Extract hour, minute, second components from current time
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: currentTime)
        
        // Set above components to seconds, minutes, seconds properties
        hours.value = timeComponents.hour ?? 0
        minutes.value = timeComponents.minute ?? 0
        seconds.value = timeComponents.second ?? 0
        
        // Trigger a screen refresh
        setNeedsDisplay()
    }
    
    deinit { // on destroy
        // Animation timer is removed from the current run loop when this view object
        // is deallocated.
        animationTimer?.remove(from: .current, forMode: .common)
    }
    
    // MARK: - Private
    
    private func handEndPoint(with radianValue: Float, and handLength: CGFloat) -> CGPoint {
        return CGPoint(x: handLength * CGFloat(cosf(radianValue)) + frame.size.width / 2.0,
                       y: handLength * CGFloat(sinf(radianValue)) + frame.size.height / 2.0)
    }
}
