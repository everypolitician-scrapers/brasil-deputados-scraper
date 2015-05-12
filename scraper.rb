#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'colorize'
require 'pry'
require 'csv'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

@BASE = 'http://www.camara.gov.br/internet/deputado/'
@url_t = @BASE + 'Dep_Lista.asp?Legislatura=%d&Partido=QQ&SX=QQ&Todos=None&UF=QQ&condic=QQ&forma=lista&nome=&ordem=nome&origem=None'

(41..55).to_a.reverse.each do |term|
  url = @url_t % term
  puts "Getting #{url}"
  page = noko(url)
  added = 0

  page.css('a[title="Detalhes do Deputado"]/@href').each do |deplink|
    dep_url = @BASE + deplink.text
    dep = noko(dep_url)
    block = dep.at_css('div.bloco')
    partido = block.xpath('.//li/strong[contains(.,"Partido")]/../text()').text.strip
    data = { 
      id: deplink.text[/id=(\d+)/, 1],
      name: dep.at_css('div#portal-mainsection h2').text.gsub('Deputado ', '').strip,
      fullname: block.xpath('.//li/strong[contains(.,"Nome civil")]/../text()').text.strip,
      party: partido.split('/')[0].strip,
      district: partido.split('/')[1].strip,
      phone: block.xpath('.//li/strong[contains(.,"Telefone")]/../text()').text.strip,
      legislaturas: block.xpath('.//li/strong[contains(.,"Legislaturas")]/../text()').text.strip,
      image: block.xpath('.//img[contains(@src, "deputado")]/@src').text,
      email: dep.xpath("//div/ul/li/a[starts-with(@href, 'mailto:')]").inner_html,
      term: term,
      source: dep_url,
    }
    added += 1
    ScraperWiki.save_sqlite([:name, :term], data)
    # puts data
  end
  puts "  Added #{added} members pf Parliament #{term}"

end

