//
//  SCChart.swift
//  chartTest
//
//  Created by sgcy on 15/7/31.
//  Copyright (c) 2015年 sgcy. All rights reserved.
//

import UIKit
let BORDER_GRAY_COLOR = UIColor(red: 37/255, green: 41/255, blue: 52/255, alpha: 1)
let ALLOW_PRESSGR_MOVEMENT = CGFloat(200)
let MINIMUM_PRESS_DURATION = 0.2

extension BarLineChartViewBase{
    public func scale(x:CGFloat,y:CGFloat,scaleX:CGFloat,scaleY:CGFloat)
    {
        var matrix = CGAffineTransformMakeTranslation(x, y)
        matrix = CGAffineTransformScale(matrix, scaleX, scaleY)
        matrix = CGAffineTransformTranslate(matrix,
            -x, -y)
        matrix = CGAffineTransformConcat(_viewPortHandler.touchMatrix, matrix)
        _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: true)
    }
    
    func press(recognizer:UILongPressGestureRecognizer)
    {
        if (_dataNotSet)
        {
            return
        }
        
        if (recognizer.state == .Changed || recognizer.state == .Began)
        {
            var h = getHighlightByTouchPoint(recognizer.locationInView(self))
            
            if (h === nil || h!.isEqual(self.lastHighlighted))
            {
               // self.highlightValue(highlight: nil, callDelegate: true)
               // self.lastHighlighted = nil
            }
            else
            {
                self.lastHighlighted = h
                self.highlightValue(highlight: h, callDelegate: true)
            }
        }
        else if (recognizer.state == UIGestureRecognizerState.Ended)
        {
            self.lastHighlighted = nil
            self.highlightValue(highlight: nil, callDelegate: true)
        }
    }
    
    public func getChartTopAndBottomValue()->[String]
    {
        return [self.leftAxis.getFormattedLabel(0).stringByReplacingOccurrencesOfString(",", withString:"", options: NSStringCompareOptions.LiteralSearch, range: nil),self.leftAxis.getFormattedLabel(self.leftAxis.entries.count - 1).stringByReplacingOccurrencesOfString(",", withString:"", options: NSStringCompareOptions.LiteralSearch, range: nil)]
    }
    
    public func scaleToFillContent(from:Int,to:Int)
    {
        let visibleXIndexs = from...to
        
        var minY :CGFloat = 10000
        var maxY :CGFloat = 0
        
        if let combineChartView = self as? CombinedChartView{
            let dataset = combineChartView.candleData.dataSets[0]
            for index in visibleXIndexs
            {
                let entry = dataset.entryForXIndex(index) as! CandleChartDataEntry
                minY = min(minY, CGFloat(entry.low))
                maxY = max(maxY, CGFloat(entry.high))
            }
        }else if let barChartView = self as? BarChartView{
            let dataset = barChartView.data!.dataSets[0]
            for index in visibleXIndexs
            {
                let entry = dataset.entryForXIndex(index) as! BarChartDataEntry
                maxY = max(maxY, CGFloat(entry.value))
            }
            minY = 0
        }
        
        var point1 = CGPoint(x: 0, y: minY)
        var point2 = CGPoint(x: 0, y: maxY)
        self.getTransformer(ChartYAxis.AxisDependency.Left).pointValueToPixel(&point1)
        self.getTransformer(ChartYAxis.AxisDependency.Left).pointValueToPixel(&point2)
        
        let scaleY = (self.viewPortHandler.contentBottom - self.viewPortHandler.contentTop)/(point1.y - point2.y + 20)
        
        self.scale(0, y:0, scaleX: 1, scaleY: scaleY * 1.0)

        let shifting:CGFloat = (self is SCBarChartView ? 0.5 : 0)
        
        var centerX = CGFloat(from + to)/2
        
        self.centerViewTo(xIndex:centerX, yValue:(minY + maxY)/2, axis: ChartYAxis.AxisDependency.Left)
    }
}


public class SCGradientLineChartView:LineChartView{
    override func initialize() {
        super.initialize()
        renderer = SCGradientLineChartRenderer(delegate: self, animator: _animator, viewPortHandler: _viewPortHandler)
        let pressGR = UILongPressGestureRecognizer(target: self, action: "press:")
        self.addGestureRecognizer(pressGR)
        pressGR.allowableMovement = ALLOW_PRESSGR_MOVEMENT
        pressGR.minimumPressDuration = MINIMUM_PRESS_DURATION
    }
    
    override public func tapGestureRecognized(recognizer: UITapGestureRecognizer)
    {

    }
        override public func pinchGestureRecognized(recognizer: UIPinchGestureRecognizer)
    {
        let render = self.renderer as! SCGradientLineChartRenderer

        if recognizer.state == .Ended || recognizer.numberOfTouches() < 2{
            render.fillFrom = nil
            render.fillTo = nil
            setNeedsDisplay()
            return
        }
        
        let point1 = recognizer.locationOfTouch(0, inView: self)
        let point2 = recognizer.locationOfTouch(1, inView: self)
        
        let value1 = self.getTransformer(ChartYAxis.AxisDependency.Left).getValueByTouchPoint(point1)
        let value2 = self.getTransformer(ChartYAxis.AxisDependency.Left).getValueByTouchPoint(point2)
        
    
        if value1.x < value2.x{
            render.fillFrom = Int(value1.x)
            render.fillTo = Int(value2.x)
        }else{
            render.fillFrom = Int(value2.x)
            render.fillTo = Int(value1.x)
        }
        
        setNeedsDisplay()
    }
    
    var highlightLayer:HighlightedLayer?
    
    public func setHighlight(xIndex: Int)
    {
        if (CGFloat(xIndex) > CGFloat(chartXMax) * _animator.phaseX)
        {
            return
        }
        let yValue = self.data!.dataSets[0].yValForXIndex(xIndex)
        if (yValue.isNaN)
        {
            return
        }
        
        var y = CGFloat(yValue) * _animator.phaseY;
        
        var point = CGPoint(x: CGFloat(xIndex), y: CGFloat(y));
        self.getTransformer(ChartYAxis.AxisDependency.Left).pointValueToPixel(&point)
        
        if highlightLayer == nil{
            highlightLayer = HighlightedLayer()
            highlightLayer!.frame = self.frame
            self.layer.addSublayer(highlightLayer)
        }
        
        highlightLayer!.point = point
        highlightLayer!.setNeedsDisplay()
        CATransaction.setDisableActions(true)

    }
    
    public func removeHighlight()
    {
        highlightLayer?.removeFromSuperlayer()
        highlightLayer = nil
    }
    
    override public func highlightValue(#highlight: ChartHighlight?, callDelegate: Bool) {
        // 十字线怎么画?同时选中上下两个图
        if (callDelegate && delegate != nil)
        {
            if (highlight == nil)
            {
                delegate!.chartValueNothingSelected!(self);
            }
            else
            {
                var e = _data.getEntryForHighlight(highlight!);
                // notify the listener
                delegate!.chartValueSelected!(self, entry: e!, dataSetIndex: highlight!.dataSetIndex, highlight: highlight!);
            }
        }
    }


}
public class SCGradientLineChartRenderer:LineChartRenderer{
   
    var fillFrom:Int?
    var fillTo:Int?
    override func drawCubic(#context: CGContext, dataSet: LineChartDataSet, entries: [ChartDataEntry]) {
        drawCubic(context: context, dataSet: dataSet, entries: entries , isDrawFill:false)
     //   if fillFrom == nil{
            drawCubic(context: context, dataSet: dataSet, entries:entries, isDrawFill: true)
            return
     //   }
      //  let slice = entries[fillFrom!...fillTo!]
      //  drawCubic(context: context, dataSet: dataSet, entries:Array(slice), isDrawFill: true)
    }
    
    internal func drawCubic(#context: CGContext, dataSet: LineChartDataSet, entries: [ChartDataEntry],isDrawFill:Bool)
    {
        var trans = delegate?.lineChartRenderer(self, transformerForAxis: dataSet.axisDependency)
        
        if entries.count < 2{
            return
        }
        
        if fillFrom != nil && isDrawFill{
            _minX = fillFrom!
            _maxX = fillTo!
        }
        
        var entryFrom = dataSet.entryForXIndex(_minX)
        var entryTo = dataSet.entryForXIndex(_maxX)
        
        var minx = max(dataSet.entryIndex(entry: entryFrom!, isEqual: true), 0)
        var maxx = min(dataSet.entryIndex(entry: entryTo!, isEqual: true) + 1, entries.count)
        
        var phaseX = _animator.phaseX
        var phaseY = _animator.phaseY
        
        // get the color that is specified for this position from the DataSet
        var drawingColor = dataSet.colors.first!
        
        var intensity = dataSet.cubicIntensity
        
        // the path for the cubic-spline
        var cubicPath = CGPathCreateMutable()
        var valueToPixelMatrix = trans!.valueToPixelMatrix
        
        var size = Int(ceil(CGFloat(maxx - minx) * phaseX + CGFloat(minx)))
        
        if (size - minx >= 2)
        {
            var prevDx: CGFloat = 0.0
            var prevDy: CGFloat = 0.0
            var curDx: CGFloat = 0.0
            var curDy: CGFloat = 0.0
            
            var prevPrev = entries[minx]
            var prev = entries[minx]
            var cur = entries[minx]
            var next = entries[minx + 1]
            
            // let the spline start
            CGPathMoveToPoint(cubicPath, &valueToPixelMatrix, CGFloat(cur.xIndex), CGFloat(cur.value) * phaseY)
            
            prevDx = CGFloat(cur.xIndex - prev.xIndex) * intensity
            prevDy = CGFloat(cur.value - prev.value) * intensity
            
            curDx = CGFloat(next.xIndex - cur.xIndex) * intensity
            curDy = CGFloat(next.value - cur.value) * intensity
            
            // the first cubic
            CGPathAddCurveToPoint(cubicPath, &valueToPixelMatrix,
                CGFloat(prev.xIndex) + prevDx, (CGFloat(prev.value) + prevDy) * phaseY,
                CGFloat(cur.xIndex) - curDx, (CGFloat(cur.value) - curDy) * phaseY,
                CGFloat(cur.xIndex), CGFloat(cur.value) * phaseY)
            
            for (var j = minx + 1, count = min(size, entries.count - 1); j < count; j++)
            {
                prevPrev = entries[j == 1 ? 0 : j - 2]
                prev = entries[j - 1]
                cur = entries[j]
                next = entries[j + 1]
                
                prevDx = CGFloat(cur.xIndex - prevPrev.xIndex) * intensity
                prevDy = CGFloat(cur.value - prevPrev.value) * intensity
                curDx = CGFloat(next.xIndex - prev.xIndex) * intensity
                curDy = CGFloat(next.value - prev.value) * intensity
                
                CGPathAddCurveToPoint(cubicPath, &valueToPixelMatrix, CGFloat(prev.xIndex) + prevDx, (CGFloat(prev.value) + prevDy) * phaseY,
                    CGFloat(cur.xIndex) - curDx,
                    (CGFloat(cur.value) - curDy) * phaseY, CGFloat(cur.xIndex), CGFloat(cur.value) * phaseY)
            }
            
            if (size > entries.count - 1)
            {
                prevPrev = entries[entries.count - (entries.count >= 3 ? 3 : 2)]
                prev = entries[entries.count - 2]
                cur = entries[entries.count - 1]
                next = cur
                
                prevDx = CGFloat(cur.xIndex - prevPrev.xIndex) * intensity
                prevDy = CGFloat(cur.value - prevPrev.value) * intensity
                curDx = CGFloat(next.xIndex - prev.xIndex) * intensity
                curDy = CGFloat(next.value - prev.value) * intensity
                
                // the last cubic
                CGPathAddCurveToPoint(cubicPath, &valueToPixelMatrix, CGFloat(prev.xIndex) + prevDx, (CGFloat(prev.value) + prevDy) * phaseY,
                    CGFloat(cur.xIndex) - curDx,
                    (CGFloat(cur.value) - curDy) * phaseY, CGFloat(cur.xIndex), CGFloat(cur.value) * phaseY)
            }
        }
        
        CGContextSaveGState(context)
        
        if (isDrawFill)
        {
            drawCubicFill(context: context, dataSet: dataSet, spline: cubicPath, matrix: valueToPixelMatrix, from: minx, to: size)
        }else{
        
            CGContextBeginPath(context)
            CGContextAddPath(context, cubicPath)
            CGContextSetStrokeColorWithColor(context, drawingColor.CGColor)
            CGContextStrokePath(context)
        }
        CGContextRestoreGState(context)
    }
    
    internal override func drawCubicFill(#context: CGContext, dataSet: LineChartDataSet, spline: CGMutablePath, var matrix: CGAffineTransform, from: Int, to: Int)
    {
        CGContextSaveGState(context)
        var fillMin = delegate!.lineChartRendererFillFormatter(self).getFillLinePosition(
            dataSet: dataSet,
            data: delegate!.lineChartRendererData(self),
            chartMaxY: delegate!.lineChartRendererChartYMax(self),
            chartMinY: delegate!.lineChartRendererChartYMin(self))
        
        var pt1 = CGPoint(x: CGFloat(to - 1), y: fillMin)
        var pt2 = CGPoint(x: CGFloat(from), y: fillMin)
        pt1 = CGPointApplyAffineTransform(pt1, matrix)
        pt2 = CGPointApplyAffineTransform(pt2, matrix)
        
        CGContextBeginPath(context)
        CGContextAddPath(context, spline)
        CGContextAddLineToPoint(context, pt1.x, pt1.y)
        CGContextAddLineToPoint(context, pt2.x, pt2.y)
        CGContextClosePath(context)
        CGContextClip(context)
        
        var colors: [CFTypeRef] = [dataSet.colors.first!.colorWithAlphaComponent(0.7).CGColor, UIColor.clearColor().CGColor]
        var colorsPointer = UnsafeMutablePointer<UnsafePointer<Void>>(colors)
        var colorsArray = CFArrayCreate(nil, colorsPointer, colors.count, nil)
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let gradient = CGGradientCreateWithColors(colorSpace, colorsArray, nil);
        let start = CGPoint(x:160, y: 0)
        
        let end = CGPoint(x: 160, y:pt1.y/10)
        CGContextDrawLinearGradient(context, gradient, start, end, 0);
        CGContextRestoreGState(context)
    }
    
    
    
}

public class HighlightedLayer:CALayer
{
    var point:CGPoint!
    public override func drawInContext(ctx: CGContext!) {
        super.drawInContext(ctx)
        CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(ctx,1.0)
        
        CGContextMoveToPoint(ctx,point.x,0)
        CGContextAddLineToPoint(ctx,point.x, self.frame.size.height)
        
        CGContextMoveToPoint(ctx,0,point.y)
        CGContextAddLineToPoint(ctx,self.frame.size.width, point.y)
        CGContextDrawPath(ctx, kCGPathStroke)
        CGContextStrokePath(ctx)
        
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddEllipseInRect(ctx,(CGRectMake (point.x-2, point.y-2, 4.0, 4.0)))
        CGContextDrawPath(ctx, kCGPathFill)
        CGContextStrokePath(ctx)
    }
}

@objc
public protocol SCChartViewDelegate
{
    optional func chartViewContentScaled(chartView: ChartViewBase)
}

public class SCCombinedChartView:CombinedChartView
{
    
    public weak var scdelegate:SCChartViewDelegate?
    
    public override func initialize() {
        super.initialize()
        let pressGR = UILongPressGestureRecognizer(target: self, action: "press:")
        self.addGestureRecognizer(pressGR)
        pressGR.allowableMovement = ALLOW_PRESSGR_MOVEMENT
        pressGR.minimumPressDuration = MINIMUM_PRESS_DURATION
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        _leftYAxisRenderer?.computeAxis(yMin: _leftAxis.axisMinimum, yMax: _leftAxis.axisMaximum)
    }
    
    var highlightLayer:HighlightedLayer?
    public func setHighlight(xIndex: Int)
    {
        if xIndex == 0{
            return
        }
        
        if (CGFloat(xIndex) > CGFloat(chartXMax) * _animator.phaseX)
        {
            return
        }
        let yValue = self.candleData.dataSets[0].yValForXIndex(xIndex)
        if (yValue.isNaN)
        {
            return
        }
        var y = CGFloat(yValue) * _animator.phaseY;
        
        var point = CGPoint(x: CGFloat(xIndex), y: y);
        self.getTransformer(ChartYAxis.AxisDependency.Left).pointValueToPixel(&point)
        
        if highlightLayer == nil{
            highlightLayer = HighlightedLayer()
            highlightLayer!.frame = self.frame
            self.layer.addSublayer(highlightLayer)
        }
        highlightLayer!.point = point
        highlightLayer!.setNeedsDisplay()
        CATransaction.setDisableActions(true)
    }
    
    public func removeHighlight()
    {
        highlightLayer?.removeFromSuperlayer()
        highlightLayer = nil
    }

    override public func tapGestureRecognized(recognizer: UITapGestureRecognizer)
    {
        
    }
    
    public weak var otherChartView:BarLineChartViewBase?
    override public func panGestureRecognized(recognizer: UIPanGestureRecognizer)
    {
        super.panGestureRecognized(recognizer)
        
        if recognizer.view == self
        {
            otherChartView?.panGestureRecognized(recognizer)
            let lower = self.lowestVisibleXIndex
            let higher = self.highestVisibleXIndex
            scaleToFillContent(lower,to:higher)
            otherChartView?.scaleToFillContent(lower,to:higher)

        }
        
    }
    
    public override func scaleToFillContent(from: Int, to: Int)
    {
        super.scaleToFillContent(from, to: to)
        self.scdelegate?.chartViewContentScaled?(self)
    }
}


public class SCBarChartView:BarChartView{
 
    internal override func initialize()
    {
        super.initialize()
        renderer = SCBarChartRender(delegate: self, animator: _animator, viewPortHandler: _viewPortHandler)
        let pressGR = UILongPressGestureRecognizer(target: self, action: "press:")
        pressGR.allowableMovement = ALLOW_PRESSGR_MOVEMENT
        pressGR.minimumPressDuration = MINIMUM_PRESS_DURATION
        self.addGestureRecognizer(pressGR)
    }
    
    var highlightLayer:HighlightedLayer?
    
    public func setHighlight(xIndex: Int)
    {
        if (CGFloat(xIndex) > CGFloat(chartXMax) * _animator.phaseX)
        {
            return
        }
        let yValue = self.data!.dataSets[0].yValForXIndex(xIndex)
        if (yValue.isNaN)
        {
            return
        }
        var y = -1;
        
        var point = CGPoint(x: CGFloat(xIndex), y: CGFloat(y));
        self.getTransformer(ChartYAxis.AxisDependency.Left).pointValueToPixel(&point)
        
        if highlightLayer == nil{
            highlightLayer = HighlightedLayer()
            highlightLayer!.frame = self.frame
            self.layer.addSublayer(highlightLayer)
        }
        highlightLayer!.point = point
        highlightLayer!.setNeedsDisplay()
    }
    
    public func removeHighlight()
    {
        highlightLayer?.removeFromSuperlayer()
        highlightLayer = nil
    }
    
    override public func highlightValue(#highlight: ChartHighlight?, callDelegate: Bool) {
        // 十字线怎么画?同时选中上下两个图
        if (callDelegate && delegate != nil)
        {
            if (highlight == nil)
            {
                delegate!.chartValueNothingSelected!(self);
            }
            else
            {
                var e = _data.getEntryForHighlight(highlight!);
                // notify the listener
                delegate!.chartValueSelected!(self, entry: e!, dataSetIndex: highlight!.dataSetIndex, highlight: highlight!);
            }
        }
    }
    
    
    override public func tapGestureRecognized(recognizer: UITapGestureRecognizer)
    {
        
    } 
    public weak var otherChartView:BarLineChartViewBase?
    override public func panGestureRecognized(recognizer: UIPanGestureRecognizer)
    {
        super.panGestureRecognized(recognizer)
        if recognizer.view == self
        {
           otherChartView?.panGestureRecognized(recognizer)
            let lower = self.lowestVisibleXIndex
            let higher = self.highestVisibleXIndex
            scaleToFillContent(lower,to:higher)
            otherChartView?.scaleToFillContent(lower,to:higher)
        }
    }
   
}


public class SCBarChartDataSet:BarChartDataSet{
    public var candleStickChartDataSet:CandleChartDataSet?
    public var increasingColor:UIColor = UIColor.redColor()
    public var decreasingColor:UIColor = UIColor.greenColor()
    override public func colorAt(index: Int) -> UIColor {
        if candleStickChartDataSet == nil{
            return super.colorAt(index)
        }else{
            let e = candleStickChartDataSet!.entryForXIndex(index) as! CandleChartDataEntry
            return (e.open < e.close ? increasingColor : decreasingColor)
        }
    }
}



public class SCBarChartRender:BarChartRenderer{
    internal override func drawDataSet(#context: CGContext, dataSet: BarChartDataSet, index: Int)
    {
        CGContextSaveGState(context)
        
        var barData = delegate!.barChartRendererData(self)
        
        var trans = delegate!.barChartRenderer(self, transformerForAxis: dataSet.axisDependency)
        
        var drawBarShadowEnabled: Bool = delegate!.barChartIsDrawBarShadowEnabled(self)
        var dataSetOffset = (barData.dataSetCount - 1)
        var groupSpace = barData.groupSpace
        var groupSpaceHalf = groupSpace / 2.0
        var barSpace = dataSet.barSpace
        var barSpaceHalf = barSpace / 2.0
        var containsStacks = dataSet.isStacked
        var isInverted = delegate!.barChartIsInverted(self, axis: dataSet.axisDependency)
        var entries = dataSet.yVals as! [BarChartDataEntry]
        var barWidth: CGFloat = 0.5
        var phaseY = _animator.phaseY
        var barRect = CGRect()
        var barShadow = CGRect()
        var y: Double
        
        // do the drawing
        for (var j = 0, count = Int(ceil(CGFloat(dataSet.entryCount) * _animator.phaseX)); j < count; j++)
        {
            var e = entries[j]
            
            // calculate the x-position, depending on datasetcount
            var x = CGFloat(e.xIndex + e.xIndex * dataSetOffset) + CGFloat(index)
                + groupSpace * CGFloat(e.xIndex) + groupSpaceHalf
            var vals = e.values
            
            if (!containsStacks || vals == nil)
            {
                y = e.value
                
                var left = x - barWidth + barSpaceHalf
                var right = x + barWidth - barSpaceHalf
                var top = isInverted ? (y <= 0.0 ? CGFloat(y) : 0) : (y >= 0.0 ? CGFloat(y) : 0)
                var bottom = isInverted ? (y >= 0.0 ? CGFloat(y) : 0) : (y <= 0.0 ? CGFloat(y) : 0)
                
                // multiply the height of the rect with the phase
                if (top > 0)
                {
                    top *= phaseY
                }
                else
                {
                    bottom *= phaseY
                }
                
                barRect.origin.x = left
                barRect.size.width = right - left
                barRect.origin.y = top
                barRect.size.height = bottom - top
                
                trans.rectValueToPixel(&barRect)
                
                if (!viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width))
                {
                    continue
                }
                
                if (!viewPortHandler.isInBoundsRight(barRect.origin.x))
                {
                    break
                }
                
                // if drawing the bar shadow is enabled
                if (drawBarShadowEnabled)
                {
                    barShadow.origin.x = barRect.origin.x
                    barShadow.origin.y = viewPortHandler.contentTop
                    barShadow.size.width = barRect.size.width
                    barShadow.size.height = viewPortHandler.contentHeight
                    
                    CGContextSetFillColorWithColor(context, dataSet.barShadowColor.CGColor)
                    CGContextFillRect(context, barShadow)
                }
                
                // Set the color for the currently drawn value. If the index is out of bounds, reuse colors.
                CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                // CGContextFillRect(context, barRect)
                //改为画圆角
                
                let path = UIBezierPath(roundedRect: barRect, cornerRadius: barRect.width/2)
                path.fill()
                CGContextFillPath(context);
            }else{
                println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            }
        }
        
        CGContextRestoreGState(context)
    }
    
}
