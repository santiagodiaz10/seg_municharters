# Replication code in *R* for "Spatial Inequalities Shaping Institutional Design. Municipal Charters in Argentina"

This repository contains data and code to reproduce interactive maps that underpin the idea of my working paper "Spatial Inequalities Shaping Institutional Design. Municipal Charters in Argentina":

> **Abstract:** This paper explores the effect of socio-economic segregation on the probability of sanctioning Municipal Charters (MC) for municipalities in Argentina. Using Census data for years 2001 and 2010, I first develop municipal segregation measures for three variables; education levels, unsatisfied basic needs, and overcrowded households. The Gini Segregation Index (G) and the Information Theory Index (H) are obtained taking advantage of the disaggregation of municipalities in census tracts units. Subsequently, exploiting the timing of plausibly exogenous provincial constitutional reforms granting municipalities the right to adopt MC, I analyse the time to reform and the main factors driving this decision. The findings indicate a positive and consistent association between segregation indexes and the likelihood of adopting a charter; the more unequal distribution of socio-economic characteristics, the swifter the municipality will have its MC sanctioned.

## Reproducibility

For this case study, I have adapted the code to showcase an example for municipalities in Cordoba province. To obtain the interactive maps below, first download the data files from **`data/`** and then run the **`R/segregation_maps.R`** script. The file contains self-explanatory code for easily reproducing the results. Georeferenced maps are handled on-the-fly using virtual file systems **`/vsizip`**, so maps will be downloaded, decompressed and loaded directly to *R*. Figures 1 and 2 are captures of the interactive maps obtained as final output.


### Figure 1: Unsatisfied Basic Needs (UBN-2010 Census) Gini Segregation:
<!-- ![Segregation in Cordoba](https://github.com/santiagodiaz10/seg_municharters/blob/main/images/cba_gini_segregation.png)
-->

<!--
```{r}
knitr::include_graphics("./images/cba_gini_segregation.PNG",  error = F)
```
-->

![Segregation in Cordoba](./images/cba_gini_segregation.png)

### Figure 2: Time to Reform Municipal Charters (MC) in years:
<!-- ![Time to reform MC in Cordoba province](https://github.com/santiagodiaz10/seg_municharters/blob/main/images/cba_time_to_co.png)
-->
![Time to reform MC in Cordoba province](./images/cba_time_to_co.png)

## Sources:

* Georeferenced maps and Unsatisfied Basic Needs (UBN) are from The National Institute of Statistics and Censuses [INDEC](https://www.indec.gob.ar/indec/web/Institucional-Indec-QuienesSomosEng). Census 2010 data at the tract level can be processed online using [REDATAM software - ECLAC](https://redatam.indec.gob.ar/).
* Georeferenced municipal areas are from the National Geographic Institute [IGN](https://www.ign.gob.ar/).

## License

The software code contained within this repository is made available under the [MIT license](http://opensource.org/licenses/mit-license.php). The data and figures are made available under the [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/) license.