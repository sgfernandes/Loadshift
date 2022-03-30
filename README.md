# Loadshift

This repository contains code and results of the hourly predictive accuracy of multiple baseline models. 

As decarbonization goals drive increasing levels of renewable generation and changing energy consumption patterns, there is a need to understand the time-based savings of energy efficiency and demand-side management (DSM) programs.  These changes in generation and consumption patterns are driving the need to develop new approaches to match demand profiles with low carbon generation resources. 

Due to the changing load shapes and generation mix, utilities are increasingly interested in measures that shift the time of energy use in addition to reducing overall energy use. Load shift (LS) is one such demand flexibility mode that enables and incentivizes customers to increase electricity consumption (“take”) during periods of surplus renewables generation, lower energy prices, and lower emissions, while reducing their consumption (“shed”) during periods of scarcity, high prices and higher emissions. 

Measurement & Verification (M&V) methods for energy efficiency projects have been developed for many years and are evolving toward increased use of automation and hourly meter data (e.g., ‘advanced M&V’ or ‘M&V 2.0’). These M&V 2.0 methods use the increased availability of utility billing interval data and the ability to quickly process large amounts of data using automated analytics. 

This code presents a method and metric to quantify baseline algorithm predictive accuracy for each hour of the year. We call this approach ‘anytime prediction’, as it assesses baseline predictive accuracy for every hour in the prediction time horizon. Anytime prediction uses a heatmap visualization approach and a median percent error to quantify hourly savings. In the context of  DF this approach offers deeper insights into hourly savings, since it is already known that model’s predictive error varies based on the magnitude of the load being predicted and the number of algorithm training data points of a similar magnitude (e.g., peak prediction error is higher than for other load magnitudes). 
