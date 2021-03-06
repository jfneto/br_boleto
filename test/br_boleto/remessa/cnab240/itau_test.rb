require 'test_helper'

describe BrBoleto::Remessa::Cnab240::Itau do
	subject { FactoryGirl.build(:remessa_cnab240_itau, lotes: lote) }
	let(:pagamento) { FactoryGirl.build(:remessa_pagamento, valor_documento: 879.66) } 
	let(:lote) { FactoryGirl.build(:remessa_lote, pagamentos: pagamento) } 

	it "deve herdar da class Base" do
		subject.class.superclass.must_equal BrBoleto::Remessa::Cnab240::Base
	end

	context "validations" do
		describe 'Validações personalizadas da conta' do
			it 'valid_carteira_required' do
				subject.conta.carteira = ''
				conta_must_be_msg_error(:carteira, :blank)
			end

			it 'valid_carteira_length' do
				subject.conta.carteira = '1234567890123456'
				conta_must_be_msg_error(:carteira, :custom_length_is, {count: 3})
			end

			it 'valid_convenio_required' do
				subject.conta.convenio = ''
				conta_must_be_msg_error(:convenio, :blank)
			end

			it 'valid_convenio_length' do
				subject.conta.convenio = '1234567890123456'
				conta_must_be_msg_error(:convenio, :custom_length_maximum, {count: 5})
			end

			it 'agencia_required' do
				subject.conta.agencia = ''
				conta_must_be_msg_error(:agencia, :blank)
			end

			it 'agencia_length' do
				subject.conta.agencia = '1234567890123456'
				conta_must_be_msg_error(:agencia, :custom_length_is, {count: 4})
			end

			private

			def conta_must_be_msg_error(attr_validation, msg_key, options_msg={})
				must_be_message_error(:base, "#{BrBoleto::Conta::Itau.human_attribute_name(attr_validation)} #{get_message(msg_key, options_msg)}")
			end
		end
	end


	describe "#convenio_lote" do
		it "deve ser preenchido com brancos " do
			subject.convenio_lote(lote).must_equal ' ' * 20
		end
		it "deve ter 20 caracteres" do
			subject.convenio_lote(lote).size.must_equal 20
		end
	end

	describe "#informacoes_da_conta" do
		it "deve ter 20 posições" do
			subject.informacoes_da_conta.size.must_equal 20
		end

		it "1 - Primeira parte = agencia 5 posicoes - ajustados com zeros a esquerda" do	
			subject.conta.agencia = '47'
			subject.informacoes_da_conta[0..4].must_equal '00047'			

			subject.conta.agencia = '1234'
			subject.informacoes_da_conta[0..4].must_equal '01234'
		end

		it "2 - Segunda parte = deve ser preenchido com branco" do
			subject.informacoes_da_conta[5].must_equal " "
		end

		it "3 - Terceira parte = deve ser preenchido com zeros" do
			subject.informacoes_da_conta[6..12].must_equal '0000000'			
		end

		it "4 - Quarta parte = conta_corrente 5 posicoes - ajustados com zeros a esquerda" do
			subject.conta.conta_corrente = '89755'
			subject.informacoes_da_conta[13..17].must_equal '89755'			

			subject.conta.conta_corrente = '1234'
			subject.informacoes_da_conta[13..17].must_equal '01234'
		end

		it "5 - Quinta parte = Se o conta_corrente_dv não for 2 digitos deve ter 1 espaço em branco" do
			subject.informacoes_da_conta[18].must_equal(' ')
		end

		it "6 - Sexta parte = Conta Corrente DV" do
			subject.conta.conta_corrente_dv = '8'
			subject.informacoes_da_conta[19..19].must_equal('8')			
		end
	end

	describe "#complemento_header_arquivo" do
		it "deve ter 15 posições" do
			subject.complemento_header_arquivo.size.must_equal 15
		end

		it "1 - Primeira parte = deve ser preenchido com zeros" do
			subject.complemento_header_arquivo[0..2].must_equal '000'
		end

		it "2 - Segunda parte = USO FEBRABAN com 12 posições em branco" do
			subject.complemento_header_arquivo[3..14].must_equal ' ' * 12
		end
	end

	describe "#complemento_p" do

		it "deve ter 34 posições" do
			subject.complemento_p(pagamento).size.must_equal 34
		end

		it "1 - Primeira parte = deve ser preenchido com zeros" do
			subject.complemento_p(pagamento)[0..6].must_equal '0000000'
		end

		it "2 - Segunda parte = conta_corrente com 5 posicoes - ajustados com zeros a esquerda" do
			subject.conta.conta_corrente = '1234'
			subject.complemento_p(pagamento)[7..11].must_equal '01234'
		
			subject.conta.conta_corrente = '26461'
			subject.complemento_p(pagamento)[7..11].must_equal '26461'
		end

		it "3 - Terceira parte = deve ser preenchido com 1 espaço em branco" do
			subject.complemento_p(pagamento)[12..12].must_equal ' '			
		end
		
		it "4 - Quarta parte = Conta Corrente DV - 1 posicao" do
			subject.conta.conta_corrente_dv = '7'
			subject.complemento_p(pagamento)[13..13].must_equal '7'
		end

		it "5 - Quinta parte = carteira com 3 posicoes ajustados com zeros a esquerda" do
			subject.conta.carteira = '21'
			subject.complemento_p(pagamento)[14..16].must_equal '021'
		end			

		it "6 - Sexta parte = Numero documento com 8 posicoes" do
			pagamento.numero_documento = '89378'
			subject.complemento_p(pagamento)[17..24].must_equal '00089378'		

			pagamento.numero_documento = '12345678'
			subject.complemento_p(pagamento)[17..24].must_equal '12345678'
		end

		it "7 - Setima parte = numero_documento DV com 1 posicao - Deve ser o ultimo digito do nosso numero" do
			pagamento.nosso_numero = '999/99999999-9'
			subject.complemento_p(pagamento)[25..25].must_equal '9'			

			pagamento.nosso_numero = '999/99999999-0'
			subject.complemento_p(pagamento)[25..25].must_equal '0'
		end

		it "8 - Oitava parte = deve ser preenchido com brancos" do
			subject.complemento_p(pagamento)[26..33].must_equal ' ' * 8
		end

	end

	describe "#segmento_p_numero_do_documento" do
		it "deve ter 15 posições" do
			subject.segmento_p_numero_do_documento(pagamento).size.must_equal 15
		end

		it "1 - Primeira parte = deve conter o numero do documento 10 posicoes - ajustados com zeros a esquerda" do	
			pagamento.expects(:numero_documento).returns("977897")
			subject.segmento_p_numero_do_documento(pagamento)[0..9].must_equal '0000977897'
		end

		it "2 - Segunda parte = deve ser preenchido com brancos" do	
			subject.segmento_p_numero_do_documento(pagamento)[10..14].must_equal ' ' * 5
		end
	end

	describe "#complemento_trailer_lote" do
		it "deve ter 217 posições" do
			subject.complemento_trailer_lote(lote, 5).size.must_equal 217
		end

		it "1 - Primeira parte = 92 posições todas preenchidas com zeros (VALORES UTILIZADOS APENAS PARA ARQUIVO DE RETORNO)" do
			subject.complemento_trailer_lote(lote, 5)[0..91].must_equal '0' * 92
		end

		it "2 - Segunda parte = 8 posições todas preenchidas com zeros (Nr. do aviso de lançamento do crédito referente aos títulos de cobrança)" do
			subject.complemento_trailer_lote(lote, 5)[92..99].must_equal (' ' * 8)
		end

		it "3 - Terceira parte = EXCLUSIVO FEBRABAN com 117 posicoes em branco" do
			subject.complemento_trailer_lote(lote, 5)[100..216].must_equal (' ' * 117)
		end
	end

	describe "segmento_r_posicao_066_a_066" do
		it { subject.segmento_r_posicao_066_a_066(pagamento).must_equal '0' }
	end
end