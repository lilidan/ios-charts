//
//  SCChart.swift
//  chartTest
//
//  Created by sgcy on 15/7/31.
//  Copyright (c) 2015年 sgcy. All rights reserved.
//

import UIKit

public class SCCombinedChartView:CombinedChartView{
    override public func pinchGestureRecognized(recognizer: UIPinchGestureRecognizer)
    {
        println("gogogo 1 ,2!")
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
                delegate!.chartValueSelected!(self, entry:e!, dataSetIndex: highlight!.dataSetIndex, highlight: highlight!);
            }
        }
    }
}
public class SCBarChartDataSet:BarChartDataSet{
    public var candleStickChartDataSet:CandleChartDataSet?
    override public func colorAt(index: Int) -> UIColor {
        if candleStickChartDataSet == nil{
            return super.colorAt(index)
        }else{
            let e = candleStickChartDataSet!.entryForXIndex(index) as! CandleChartDataEntry
            return (e.open < e.close ? candleStickChartDataSet!.increasingColor! : candleStickChartDataSet!.decreasingColor!)
        }
    }
}
public class SCBarChartView:BarChartView{
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