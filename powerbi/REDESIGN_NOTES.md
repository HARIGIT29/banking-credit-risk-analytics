# Retail Banking Credit Risk Analytics — UI/UX Redesign

This copy preserves the existing semantic model and report measures while applying a banking/fintech executive UI pass.

## Changes
- Dark left navigation rail with active-page highlight and dataset context.
- Consistent executive header and historical data-period badge.
- Rebalanced KPI rows and chart grids for 16:9 report canvas.
- White analytical cards on a soft neutral canvas.
- Consistent navy/teal/blue/amber/coral palette.
- Page 01 adds a third analytical visual (default rate by age group) and a portfolio readout panel using existing model fields/measures.
- Page 04 keeps the drillthrough/back behaviour and gives the monitoring visuals a larger analysis area.
- Page 05 is presented as a documentation-style methodology page.
- Page 03 month charts are explicitly sorted using MonthIndex rather than the text label.

The underlying dataset, measures, queries, and semantic model are not intentionally rewritten.

## Alignment revision
- Reduced the in-canvas navigation rail to 165px so the report content remains visible in the Power BI editor workspace.
- Rebalanced all content onto a consistent 1000px working area with aligned headers, KPI rows, filters, chart grids and footers.
- Increased KPI card heights and reduced title/value font sizes to prevent clipping.
- Kept the report canvas at 1280×720 (16:9).
