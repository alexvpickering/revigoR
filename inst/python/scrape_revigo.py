import werkzeug
werkzeug.cached_property = werkzeug.utils.cached_property
from robobrowser import RoboBrowser
import re
import os.path

def scrape_revigo(data_dir):

    f = open(os.path.join(data_dir, "goterms.txt"), "r")
    goterms = f.read()
    f.close()
    
    br = RoboBrowser(parser="lxml")
    br.open("http://revigo.irb.hr/")
    
    form = br.get_form()
    form["ctl00$MasterContent$txtGOInput"].value = goterms
    
    # fails here
    # possible reason https://stackoverflow.com/questions/38220285/can-not-submit-a-form-with-robobrowser-invalid-submit-error
    br.submit_form(form)
    
    download_rsc_link = br.find("a", href=re.compile("toR.jsp"))
    br.follow_link(download_rsc_link)
    r_code = br.response.content.decode("utf-8")
    
    f = open(os.path.join(data_dir, "rsc.R"), "a")
    f.write(r_code)
    f.close()
    
    br.back()
    
    download_csv_link = br.find("a", href=re.compile("export.jsp"))
    br.follow_link(download_csv_link)
    csv_content = br.response.content.decode("utf-8")
    
    f = open(os.path.join(data_dir, "rsc.csv"), "a")
    f.write(csv_content)
    f.close()
    
    br.back()
    
    download_tree_link = br.find("a", href=re.compile("toR_treemap.jsp"))
    br.follow_link(download_tree_link)
    r_code = br.response.content.decode("utf-8")
    
    f = open(os.path.join(data_dir, "tree_map.R"), "a")
    f.write(r_code)
    f.close()
    
    br.back()
    
    download_csv_link = br.find("a", href=re.compile("export_treemap.jsp"))
    br.follow_link(download_csv_link)
    csv_content = br.response.content.decode("utf-8")
    
    
    f = open(os.path.join(data_dir, "tree_map.csv"), "a")
    f.write(csv_content)
    f.close()
    
    br.back()
    
    # get cytoscape graph
    cytoscape_link = br.find("a", href=re.compile("download.jsp"))
    br.follow_link(cytoscape_link)
    cytoscape_content = br.response.content.decode("utf-8")
    
    
    f = open(os.path.join(data_dir, "cytoscape_map.xgmml"), "a")
    f.write(cytoscape_content)
    f.close()
