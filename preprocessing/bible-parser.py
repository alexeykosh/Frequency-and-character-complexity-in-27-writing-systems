from selenium import webdriver
from bs4 import BeautifulSoup
import time
from random import randint

# url = ('https://www.bible.com/bible/2834/'\
# 	'LUK.19.%EA%95%A2%EA%95%8C%EA%94%B3')
# lang = 'Vaii'
# url = 'https://www.bible.com/bible/2065/MAT.INTRO1.CRLS'
# lang = 'Cree'
# url = 'https://www.bible.com/bible/2287/MAT.1.GKHB'
# lang = 'Khmer'
# url = 'https://www.bible.com/bible/1926/MAT.1.CHR'
# lang = 'Cherokee'
# url = 'https://www.bible.com/bible/1899/MAT.1.IRVTAM'
# lang = 'Tamil'
# url = 'https://www.bible.com/bible/1712/GEN.1.TOT11'
# lang = 'Tibetan'
# url = 'https://www.bible.com/bible/1687/EXO.16.PUNOVBSI'
# lang = 'Punjabi'
# url = 'https://chop.bible.com/bible/2545/GEN.1.brb'
# lang = 'Brao'
# url = 'https://chop.bible.com/bible/1917/GEN.INTRO1.sylB'
# lang = 'Sylheti'
url = 'https://www.bible.com/bible/1727/GEN.35.%E0%BA%9E%E0%BA%84%E0%BA%9E'
lang = 'lao'


driver = webdriver.Firefox()
driver.get(url)

while True:
    soup = BeautifulSoup(driver.page_source, 'lxml')
    table = soup.find_all(class_='reader')
    res = ''.join(e for e in table[0].text.lower() if e.isalnum())
    with open('texts/' + lang + '.txt', 'a+') as file:
        file.writelines(res)
    try:
        url = driver.current_url
        driver.find_element_by_css_selector('html.i-amphtml-singledoc.'\
        	'i-amphtml-standalone body.sans-serif.mv6.amp-mode-mouse'\
        	' div.body.mt5 div.mw6.center.pa3.pt4.pb7.mt6 a.bible-nav-'\
        	'button.fixed.br-100.ba.b--yv-gray15.bg-white.flex.'\
        	'items-center.justify-center.nav-right.right-1').click()
        time.sleep(randint(1, 3))
    except:
        print(url)
        break

driver.quit()
