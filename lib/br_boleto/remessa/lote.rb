# -*- encoding: utf-8 -*-
module BrBoleto
	module Remessa
		class Lote
			# Seguindo a interface do Active Model para:
			# * Validações;
			# * Internacionalização;
			# * Nomes das classes para serem manipuladas;
			#
			include ActiveModel::Model

			# variavel que terá os pagamentos no qual será gerado o lote do arquivo de remessa
			# Pode haver 1 ou vários pagamentos para o mesmo arquivo
			attr_accessor :pagamentos

			def self.class_for_pagamentos
				BrBoleto::Remessa::Pagamento
			end

			def initialize(attributes = {})
				self.pagamentos = [] # Para poder utilizar o << para incrementar o array
				assign_attributes(attributes)
				yield self if block_given?
			end

			def assign_attributes(attributes)
				attributes ||= {}
				attributes.each do |name, value|
					send("#{name}=", value)
				end
			end

			validates_each :pagamentos do |record, attr, value|
				record.errors.add(attr, 'não pode estar vazio.') if value.empty?
				value.each do |pagamento|
					if pagamento.is_a? record.class.class_for_pagamentos
						if pagamento.invalid?
							pagamento.errors.full_messages.each { |msg| record.errors.add(attr, msg) }
						end
					else
						record.errors.add(attr, 'cada item deve ser um objeto Pagamento.')
					end
				end				
			end

			# O atributo pagamentos sempre irá retornar umm Array 
			def pagamentos
				@pagamentos = [@pagamentos].flatten
			end
		end
	end
end