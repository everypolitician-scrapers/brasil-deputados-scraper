#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read)
end

@BASE = 'http://www.camara.gov.br/internet/deputado/'
@url_t = @BASE + 'Dep_Lista.asp?Legislatura=%d&Partido=QQ&SX=QQ&Todos=None&UF=QQ&condic=QQ&forma=lista&nome=&ordem=nome&origem=None'

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil

# (41..55).to_a.reverse.each do |term|
(55..55).to_a.reverse.each do |term|
  url = @url_t % term
  page = noko(url)

  page.css('a[title="Detalhes do Deputado"]/@href').each do |deplink|
    dep_url = @BASE + deplink.text
    dep = noko(dep_url)

    block = dep.at_css('div.bloco')
    partido = block.xpath('.//li/strong[contains(.,"Partido")]/../text()').text.tidy
    data = {
      id:           deplink.text[/id=(\d+)/, 1],
      name:         dep.at_css('div#portal-mainsection h2').text.gsub(/Deputad[ao] /, '').tidy,
      fullname:     block.xpath('.//li/strong[contains(.,"Nome civil")]/../text()').text.tidy,
      party:        partido.split('/')[0].tidy,
      party_id:     partido.split('/')[0].tidy,
      district:     partido.split('/')[1].tidy,
      birth_date:   dep.xpath('//span[contains(.,"Nascimento:")]//following-sibling::strong').text.tidy,
      phone:        block.xpath('.//li/strong[contains(.,"Telefone")]/../text()').text.tidy,
      legislaturas: block.xpath('.//li/strong[contains(.,"Legislaturas")]/../text()').text.tidy,
      image:        block.xpath('.//img[contains(@src, "deputado")]/@src').text,
      email:        dep.xpath("//div/ul/li/a[starts-with(@href, 'mailto:')]").inner_html,
      term:         term,
      source:       dep_url,
    }
    puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
    ScraperWiki.save_sqlite(%i[id term], data)
  end
end
