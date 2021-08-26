# Multi Pivot Table Generator

This folder serves to parse meter prediction output data. Specifically, we support:
- Handling multiple files of data in one go, using `data_list` in the second and third blocks
- Seperating all rows into weekdays or weekends
- Mapping dates to seasons for categorical analyses
- Decomposing meterIDs in the format `METER_NAME.ENTRY_NUM`
- Produce violin plots, heat maps, and time plots
- Simultaneously create any and all requested pivot tables, reporting output in one file if desiered

We use the `.ipynb` file to work on the code, while maintaining a seperate `.py` version helps with portability and version control.

