library(modelr)
library(ggplot2)
library(dplyr)
library(lme4)
library(lmerTest)
library(sjPlot) 
library(effects)
library(showtext)
library(ggeffects)
library(ggpubr)
library(lingtypology)
library(ggrepel)
library(MuMIn)
library(Cairo)
library(sysfonts)
library(broom.mixed)
library(sf)
library(viridis)
library(ggridges)
library(tibble)
library(modelbased)


# Setting the theme for ggplot
theme_set(theme_bw())


# Data loading
# !!!
# data <- read.csv('preprocessing/final_.csv')
data <- read.csv('data/final_correction.csv')
nrow(data)
# !!!
data <- data[data$ISO_language != 'heb',]
## Log-transforming relative frequency
data$Relative_frequency_l <- log(data$Relative_frequency)
## Correlation test
cor.test(data$Perimetric_complexity, 
         data$Compression, 
         method = "pearson")
  
## SI table
data %>%
  group_by(ISO_script) %>% 
  summarise(LengthScript = n(), across()) %>%
  distinct(ISO_script, .keep_all = TRUE) %>%
  mutate(Family = stringr::str_replace(Family, 'Mainland SE Asia',
                                        'Mainland Southeast Asia')) %>%
  arrange(ISO_language) %>%
  select(ISO_language, ISO_script, Family, Sum_count, LengthScript, Source) %>%
  write.csv(.,file = 'data/script_table.csv')

# Figure 1
dist <- data %>%
  distinct(ISO_script, .keep_all = TRUE) %>%
  mutate(Family = stringr::str_replace(Family, 'Mainland SE Asia',
                                       'Mainland Southeast Asia'))
## Setting coordinates that could not be retrieved using lingtypology
dist$Language <- lang.iso(dist$ISO_language)
dist$lat <- lat.lang(dist$Language)
dist$lon <- long.lang(dist$Language)
dist[dist$ISO_language == 'chr',]$lat <- 35.8513
dist[dist$ISO_language == 'chr',]$lon <- -94.9878
dist[dist$ISO_language == 'cre',]$lat <- 66.578227
dist[dist$ISO_language == 'cre',]$lon <- -93.270105
dist %>%
  ggplot(aes(x=lon, y=lat))+
    coord_sf(xlim = c(-100, 120),ylim = c(0, 75), expand = TRUE)+
    borders("world", colour=alpha("gray50", .2), fill=alpha("gray50", 0))+
    geom_point(aes(color=Family))+
    geom_text_repel(aes(label=ISO_script))+
    theme_void()+
    theme(legend.position = 'bottom')+
    scale_color_viridis(discrete=TRUE)+
    theme(text = element_text(size = 12)) 
ggsave('figures/fig1.pdf', dpi=300, width = 8, height = 6)
knitr::plot_crop('figures/fig1.pdf')


# Mixed-effects linear regression
## Perimetric complexity models (full and null)
model_full_p <- lmer(formula = Perimetric_complexity ~ 1 + Relative_frequency_l
                     + (1 + Relative_frequency_l|ISO_script), data=data)
model_null_p <- lmer(formula =Perimetric_complexity ~ 1 + (1|ISO_script), 
                     data=data)
## Comparing the AIC of the full model
if (abs(AIC(model_full_p) - AIC(model_null_p)) > 2){
  'Δ AIC > 2'
} else {
  'Δ AIC < 2'
}
## Summary
summary(model_full_p)
## Confidence intervals
confint(model_full_p)

## Algorithmic complexity models (full and null)
model_full_c <- lmer(formula = Compression ~ 1 + Relative_frequency_l +
                       (1 + Relative_frequency_l|ISO_script), data=data)
model_null_c <- lmer(formula =Compression ~ 1 + (1|ISO_script), data=data)
## AIC comparison 
if (abs(AIC(model_full_c) - AIC(model_null_c)) > 2){
  'Δ AIC > 2'
} else {
  'Δ AIC < 2'
}
## Summary
summary(model_full_c)
## Confidence intervals
confint(model_full_c)


## Controlling for family: algorithmic complexity model
model_null_c_f <- lmer(formula =Compression ~ 1 + (1|Family:ISO_script), data=data)
model_full_c_f <- lmer(formula = Compression ~ 1 + Relative_frequency_l + (1 + Relative_frequency_l|Family:ISO_script), data=data)
## AIC comparison
if (abs(AIC(model_full_c_f) - AIC(model_null_c_f)) > 2){
  'Δ AIC > 2'
} else {
  'Δ AIC < 2'
}
## Summary
summary(model_full_c_f)
## Confidence intervals
confint(model_full_c_f)


## Controlling for family: perimetric complexity model
model_null_p_f <- lmer(formula =Perimetric_complexity ~ 1 + (1|Family: ISO_script), data=data)
model_full_p_f <- lmer(formula = Perimetric_complexity ~ 1 + Relative_frequency_l + (1 + Relative_frequency_l|Family:ISO_script), data=data)
## AIC comparison
if (abs(AIC(model_full_p_f) - AIC(model_null_p_f)) > 2){
  'Δ AIC > 2'
} else {
  'Δ AIC < 2'
}
## Summary
confint(model_full_p_f)
## Confidencce intervals
summary(model_full_p)

# Figure 2
## Extracting model confidence interval (perimetric complexity)
p_sim <- data.frame(Relative_frequency_l = seq(min(data$Relative_frequency_l), max(data$Relative_frequency_l), .01)
                     )
fit.mat <- model.matrix(~ Relative_frequency_l, p_sim) 
cis <- diag(fit.mat %*% tcrossprod(vcov(model_full_p), fit.mat))
p_sim$Perimetric_complexity_ <- predict(model_full_p, p_sim, re.form = NA)
p_sim$lwr <- p_sim$Perimetric_complexity-1.96*sqrt(cis)
p_sim$upr <- p_sim$Perimetric_complexity+1.96*sqrt(cis)
p_sim <- p_sim %>%
  rename(Relative_frequency_l_ = Relative_frequency_l)
## Panel A with Thai examples
script <- 'Thai'
## Correct the character's encoding
thai <- data %>%
  filter(ISO_script == script)  %>%
  mutate(textfile = as.character(textfile))
Encoding(stringi::stri_enc_toutf8(thai$textfile[1]))
## Plot the panel
p1 <- ggplot()+
  theme(text=element_text(family="Arial Unicode MS"))+
  geom_text_repel(data=thai, aes(x=Relative_frequency_l, 
                                 y=Perimetric_complexity,
                                 label=stringi::stri_enc_toutf8(textfile)),
                  family="Arial Unicode MS",
                  nudge_x = 0.25, 
                  nudge_y = 0.25,
                  size=7
  )+
  geom_point(data=data,
             aes(x=Relative_frequency_l,
                 y=Perimetric_complexity),
             alpha=0.1)+
  geom_point(aes(x=Relative_frequency_l, y=Perimetric_complexity), data=thai)+
  geom_ribbon(data=p_sim,
              aes(x=Relative_frequency_l_,
                  y=Perimetric_complexity_,
                  ymin = lwr,
                  ymax = upr),
              alpha = .3,
              fill = "red")+
  geom_line(data=p_sim,
            aes(x=Relative_frequency_l_,
                y=Perimetric_complexity_),
            size = 1, color = "red")+
  scale_y_continuous(breaks = seq(0, max(data$Perimetric_complexity),
                                  by = 20))+
  scale_x_continuous(breaks = seq(-15, 0,
                                  by = 3))+
  xlab('Frequency (log-transformed)')+
  ylab('Perimetric complexity')+   
  theme(text = element_text(size = 20))     
## Extracting model confidence interval (algorithmic complexity)
p_sim <- data.frame(Relative_frequency_l= seq(min(data$Relative_frequency_l),
                          max(data$Relative_frequency_l), .01)
                     )
fit.mat <- model.matrix(~ Relative_frequency_l, p_sim) 
cis <- diag(fit.mat %*% tcrossprod(vcov(model_full_c), fit.mat))
p_sim$Compression <- predict(model_full_c, p_sim, re.form = NA)
p_sim$lwr <- p_sim$Compression-1.96*sqrt(cis)
p_sim$upr <- p_sim$Compression+1.96*sqrt(cis)
## Panel B
script <- 'Mlym'
mlym <- data %>%
  filter(ISO_script == script)  %>%
  mutate(textfile = as.character(textfile))
p2 <- ggplot()+
  theme(text=element_text(family="Arial Unicode MS"))+
  geom_text_repel(data=mlym, aes(x=Relative_frequency_l, 
                                 y=Compression,
                                 label=stringi::stri_enc_toutf8(textfile)),
                  family="Arial Unicode MS",
                  nudge_x = 0.25, 
                  nudge_y = 0.25,
                  size=7
  )+
  geom_point(data=data,
             aes(x=Relative_frequency_l,
                 y=Compression),
             alpha=0.1)+
  geom_point(aes(x=Relative_frequency_l, y=Compression), data=mlym)+
  geom_ribbon(data=p_sim,
              aes(x=Relative_frequency_l,
                  y=Compression,
                  ymin = lwr,
                  ymax = upr),
              alpha = .3,
              fill = "blue")+
  geom_line(data=p_sim,
            aes(x=Relative_frequency_l,
                y=Compression),
            size = 1, color = "blue")+
  scale_y_continuous(breaks = seq(0, max(data$Compression),
                                  by = 200))+
  scale_x_continuous(breaks = seq(-15, 0,
                                  by = 3))+
  xlab('Frequency (log-transformed)')+
  ylab('Algorithmic complexity')+
  theme(text = element_text(size = 20)) 
## Combining two panels
ggarrange(p1, p2, 
          labels = c("A", "B"),
          ncol = 2, nrow = 1)
ggsave('figures/fig2.pdf',
       width = 16,
       height = 8,
       device = cairo_pdf)


# Figure 3
## Function to plot individual predictions for perimetric complexity
plot_individ_pred_p <- function(script){
  data %>%
    filter(ISO_script == script) %>%
    ggplot(aes(x=exp(Relative_frequency_l), y=Perimetric_complexity))+
    geom_line(data=predicted_values_p[predicted_values_p$ISO_script == script,],
              aes(x=exp(Relative_frequency_l), 
                  y=pred))+
    theme(text=element_text(family="Arial Unicode MS"))+
    geom_point(alpha=0.5)+
    geom_text_repel(
      aes(label=stringi::stri_enc_toutf8(textfile)),
      family = 'Arial Unicode MS',
      # nudge_x = 0.25, nudge_y = 0.25, 
      # check_overlap = T,
      size=6
    )
}
## Same function but for algorithmic complexity
plot_individ_pred_c <- function(script){
  data %>%
    filter(ISO_script == script) %>%
    ggplot(aes(x=exp(Relative_frequency_l), y=Compression))+
    geom_line(data=predicted_values_c[predicted_values_c$ISO_script == script,],
              aes(x=exp(Relative_frequency_l), 
                  y=pred))+
    theme(text=element_text(family="Arial Unicode MS"))+
    geom_point(alpha=0.5)+
    geom_text_repel(
      aes(label=stringi::stri_enc_toutf8(textfile)),
      family = 'Arial Unicode MS',
      # nudge_x = 0.25, nudge_y = 0.25, 
      # check_overlap = T,
      size=6
    )
}
## Panel A
p_1_ <- plot_individ_pred_p('Guru')+
  theme(text = element_text(size = 14),
        axis.text = element_text(size=14),
        plot.margin = margin(l = 18, b=5, t=5, r=5))+
  xlab('Frequency (log-scale)')+
  ylab('Perimetric complexity')+
  scale_x_log10(labels = scales::comma)

p_2_ <- predicted_values_p %>% 
  ggplot(aes(Relative_frequency_l, pred))+
  geom_point(data=data,
             aes(x=Relative_frequency_l, 
                 y=Perimetric_complexity, 
                 color=Family), alpha=0.7)+
  geom_line()+
  theme(legend.position = "none")+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), 
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())+
  facet_wrap(~ISO_script, ncol=5)+
  scale_color_viridis(discrete=TRUE)+
  theme(text = element_text(size = 20))+
  theme(legend.position="none",
      strip.background=element_rect(colour="black",
                                    fill=NA))
c_fig3 <- ggarrange(p_1_, p_2_, heights = c(0.5, 1), ncol = 1, nrow = 2)
## Panel B
p_1_c <- plot_individ_pred_c('Guru')+
  theme(text = element_text(size = 14), 
        axis.text = element_text(size=14),
        plot.margin = margin(l = 18, b=5, t=5, r=5))+
  xlab('Frequency (log-scale)')+
  ylab('Algorithmic complexity')+
  scale_x_log10(labels = scales::comma)
p_2_c <- predicted_values_c %>% 
  ggplot(aes(Relative_frequency_l, pred))+
  geom_point(data=data,
             aes(x=Relative_frequency_l, 
                 y=Compression, 
                 color=Family), alpha=0.7)+
  geom_line()+
  theme(legend.position = "none")+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), 
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())+
  facet_wrap(~ISO_script, ncol=5)+
  scale_color_viridis(discrete=TRUE)+
  theme(text = element_text(size = 20))+
  theme(legend.position="none",
      strip.background=element_rect(colour="black",
                                    fill=NA))
p_fig3 <- ggarrange(p_1_c, p_2_c, heights = c(0.5, 1), ncol = 1, nrow = 2)
ggarrange(c_fig3, p_fig3, 
          ncol = 2, 
          nrow = 1, 
          labels = c("A", "B"))
ggsave('figures/fig3.pdf',
       width = 16,
       height = 8,
       device = cairo_pdf)

# Figure 4
## Initial model
re_perim <- data.frame(coef(model_full_p)$ISO_script) %>%
  rownames_to_column(var='ISO_script') %>%
  ggplot(aes(y=ISO_script, x=Relative_frequency_l))+
  geom_point()+
  geom_vline(xintercept = 0,
             linetype="dashed",
             color = "red",
             size=0.5)+
  xlim(-5, 1)+
  xlab('Random slope values')+
  ylab('Script name (ISO 15924 code)')
re_compr <- data.frame(coef(model_full_c)$ISO_script) %>%
  rownames_to_column(var='ISO_script') %>%
  ggplot(aes(y=ISO_script, x=Relative_frequency_l))+
  geom_point()+
  geom_vline(xintercept = 0,
             linetype="dashed",
             color = "red",
             size=0.5)+
  xlim(-50, 10)+
  xlab('Random slope values')+
  ylab('Script name (ISO 15924 code)')
ggarrange(re_perim, re_compr, ncol=2, nrow=1, labels = c("A", "B"))
ggsave('figures/fig4.pdf',
       width = 10,
       height = 5,
       device = cairo_pdf)
## Models with nesting
### Get coefficients from the nested model
nested_rs_p <- data.frame(coef(model_full_p_f)$`Family:ISO_script`) %>% 
  rownames_to_column(var='Family_ISO_script') %>% 
  tidyr::separate(Family_ISO_script, c("Family","ISO_script"), 
                  sep = ":")
nested_rs_c <- data.frame(coef(model_full_c_f)$`Family:ISO_script`) %>% 
  rownames_to_column(var='Family_ISO_script') %>% 
  tidyr::separate(Family_ISO_script, c("Family","ISO_script"), 
                  sep = ":")
### Plotting
re_perim_n <- nested_rs_p %>%
  ggplot(aes(y=ISO_script, x=Relative_frequency_l))+
  geom_point()+
  geom_vline(xintercept = 0,
             linetype="dashed",
             color = "red",
             size=0.5)+
  xlim(-5, 1)+
  xlab('Random slope values')+
  ylab('Script name (ISO 15924 code)')
re_compr_n <- nested_rs_c %>%
  ggplot(aes(y=ISO_script, x=Relative_frequency_l))+
  geom_point()+
  geom_vline(xintercept = 0,
             linetype="dashed",
             color = "red",
             size=0.5)+
  xlim(-50, 10)+
  xlab('Random slope values')+
  ylab('Script name (ISO 15924 code)')
ggarrange(re_perim_n, re_compr_n, ncol=2, nrow=1, labels = c("A", "B"))
ggsave('figures/fig4_n.pdf',
       width = 10,
       height = 5,
       device = cairo_pdf)

## model-based individual-level predictions
### https://easystats.github.io/modelbased/articles/estimate_grouplevel.html
# group_level <- function(model){
#   random <- estimate_grouplevel(model, group='Relative_frequency_l')
#   random[random$Parameter == 'Relative_frequency_l',] %>%
#     arrange(Coefficient) %>%    
#     mutate(name=factor(Level, levels=Level)) %>%
#     ggplot(aes(y=Level, x=Coefficient))+
#     geom_point()+
#     geom_pointrange(aes(xmin=CI_low, xmax=CI_high))+
#     geom_vline(xintercept = 0,
#                linetype="dashed",
#                color = "red",
#                size=0.5)+
#     # xlim(-5, 5)+
#     xlab('Random slope values (z-score)')+
#     ylab('Script name (ISO 15924 code)')
# }
# 
# group_level(model = model_full_c)
# 
# group_level(model = model_full_p)
