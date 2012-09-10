%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'rabl'
require 'solr_wrapper'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'url_helpers'
require_relative "config"

helpers URLHelpers

set :views, File.expand_path('views', File.dirname(__FILE__))

# Register RABL
Rabl.register!

# Initialise statsd
statsd = Statsd.new('localhost').tap {|c| c.namespace = 'govuk.app.contentapi'}

require "govuk_content_models"
require "govuk_content_models/require_all"

def custom_404
  halt 404, render(:rabl, :not_found, format: "json")
end

def custom_410
  halt 410, render(:rabl, :gone, format: "json")
end

class Artefact
  attr_accessor :edition
  field :description, type: String
end

def format_content(string)
  if @content_format == "html"
    Govspeak::Document.new(string, auto_ids: false).to_html
  else
    string
  end
end

# Render RABL
get "/search.json" do
  begin
    params[:index] ||= 'mainstream'

    if params[:index] == 'mainstream'
      index = SolrWrapper.new(DelSolr::Client.new(settings.mainstream_solr), settings.recommended_format)
    elsif params[:index] == 'whitehall'
      index = SolrWrapper.new(DelSolr::Client.new(settings.inside_solr), settings.recommended_format)
    else
      raise "What do you want?"
    end
    statsd.time("request.search.q.#{params[:q]}") {
      @results = index.search(params[:q])
    }

    content_type :json
    render :rabl, :search, format: "json"
  rescue Errno::ECONNREFUSED
    statsd.increment('request.search.unavailable')
    halt 503, render(:rabl, :unavailable, format: "json")
  end
end

get "/tags.json" do
  if params[:type]
    statsd.time("request.tags.type.#{params[:type]}") {
      @tags = Tag.where(tag_type: params[:type])
    }
  else
    statsd.time('request.tags.all') {
      @tags = Tag.all
    }
  end

  content_type :json
  render :rabl, :tags, format: "json"
end

get "/tags/:id.json" do
  statsd.time("request.tag.#{params[:id]}") {
    @tag = Tag.where(tag_id: params[:id]).first
  }
  content_type :json

  if @tag
    render :rabl, :tag, format: "json"
  else
    custom_404
  end
end

get "/with_tag.json" do
  tag_ids = params[:tag].split(',')
  tags = tag_ids.map { |ti| Tag.where(tag_id: ti).first }.compact

  custom_404 unless tags.length == tag_ids.length

  statsd.time("request.with_tag.multi.#{tag_ids.length}") {
    artefacts = Artefact.any_in(tag_ids: tag_ids)
  }

  statsd.time('request.with_tag.map_results') {
    @results = artefacts.map { |r|
      if r.owning_app == 'publisher'
        r.edition = Edition.where(slug: r.slug, state: 'published').first
        if r.edition
          r
        else
          nil
        end
      else
        r
      end
    }

    @results.compact!
  }

  content_type :json
  render :rabl, :with_tag, format: "json"
end

get "/:id.json" do
  statsd.time("request.id.#{params[:id]}") {
    @artefact = Artefact.where(slug: params[:id]).first
  }
  custom_404 unless @artefact

  @content_format = (params[:content_format] == "govspeak") ? "govspeak" : "html"

  if @artefact.owning_app == 'publisher'
    statsd.time("request.id.#{params[:id]}.edition") {
      @artefact.edition = Edition.where(slug: @artefact.slug, state: 'published').first
    }
    unless @artefact.edition
      if Edition.where(slug: @artefact.slug, state: 'archived').any?
        custom_410
      else
        custom_404
      end
    end
  end

  content_type :json
  render :rabl, :artefact, format: "json"
end
