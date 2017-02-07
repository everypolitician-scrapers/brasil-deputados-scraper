#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  warn url
  Nokogiri::HTML(open(url).read)
end

@BASE = 'http://www.camara.gov.br/internet/deputado/'
@url_t = @BASE + 'Dep_Lista.asp?Legislatura=%d&Partido=QQ&SX=QQ&Todos=None&UF=QQ&condic=QQ&forma=lista&nome=&ordem=nome&origem=None'

#  (41..55).to_a.reverse.each do |term|
(55..55).to_a.reverse.each do |term|
  url = @url_t % term
  puts "Getting #{url}"
  page = noko(url)
  added = 0
  skipped = 0

  page.css('a[title="Detalhes do Deputado"]/@href').each do |deplink|
    dep_url = @BASE + deplink.text
    dep = noko(dep_url)

    binding.pry if dep_url.include? '189171'
    block = dep.at_css('div.bloco')
    partido = block.xpath('.//li/strong[contains(.,"Partido")]/../text()').text.strip
    data = {
      id:           deplink.text[/id=(\d+)/, 1],
      name:         dep.at_css('div#portal-mainsection h2').text.gsub(/Deputad[ao] /, '').strip,
      fullname:     block.xpath('.//li/strong[contains(.,"Nome civil")]/../text()').text.strip,
      party:        partido.split('/')[0].strip,
      party_id:     partido.split('/')[0].strip,
      district:     partido.split('/')[1].strip,
      birth_date:   dep.xpath('//span[contains(.,"Nascimento:")]//following-sibling::strong').text.strip,
      phone:        block.xpath('.//li/strong[contains(.,"Telefone")]/../text()').text.strip,
      legislaturas: block.xpath('.//li/strong[contains(.,"Legislaturas")]/../text()').text.strip,
      image:        block.xpath('.//img[contains(@src, "deputado")]/@src').text,
      email:        dep.xpath("//div/ul/li/a[starts-with(@href, 'mailto:')]").inner_html,
      term:         term,
      source:       dep_url,
    }
    added += 1
    warn data[:birth_date]
    ScraperWiki.save_sqlite(%i(name term), data)
  end
  puts "  Added #{added} and skipped #{skipped} members of Parliament #{term}"
end
