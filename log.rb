#!/usr/bin/env ruby

# Copyright (C) 2016, Alex Taber
#
# This file is part of Ruby Discord Logger
#
# Ruby Discord Logger is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ruby Discord Logger is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ruby Discord Logger.  If not, see <http://www.gnu.org/licenses/>.

require 'mongo'
require 'discordrb'

loggingbot = Discordrb::Bot.new token: 'MjIwODcxNzE5ODk4ODQxMDg5.Cqmmhw.TSWQKUVw5BEfMbvvsdz4Wczdu0E', application_id: 220871719898841089

ignored_channels = []

mongo_client = Mongo::Client.new('mongodb://127.0.0.1:27017/logs')
logs_db = mongo_client.database

Mongo::Logger.logger.level = ::Logger::FATAL

loggingbot.message do |event|
  break if ignored_channels.include? event.channel.name

  channel_collection = mongo_client[event.channel.name.to_sym]

  attachments = event.message.attachments
  attachments.map! { |attachment| [attachment.filename, attachment.url] } unless attachments.empty?

  message = { user: event.author.name, content: event.content, attachments: attachments, avatar: event.author.avatar_url, time: event.timestamp, channel: event.channel.name, message_id: event.message.id }

  result = channel_collection.insert_one(message)
end

loggingbot.message_edit do |event|
  break if ignored_channels.include? event.channel.name

  channel_collection = mongo_client[event.channel.name.to_sym]

  edit = { content: event.content, time: event.timestamp, message_id: event.message.id, is_edit: true }

  result = channel_collection.insert_one(edit)
end

loggingbot.run
