### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ dc734eab-c244-4337-a0f3-469d77045eec
begin
	import Pkg
	Pkg.activate(mktempdir())
	using Pkg
	Pkg.add(["Plots", "PlutoUI"])
end


# ╔═╡ e1a7f2da-a38b-4b3c-a238-076769e46408
begin	
using Plots, PlutoUI
function exp_ccdf(n, t; p_vec = ones(n), m = 1, r = 1, normalize = true)   
    @assert length(p_vec) == n
	    
    # Normalize probabilities
    if normalize
        p_vec = p_vec ./ sum(p_vec)    
    end   
    # Initialize probability P
    P_cdf = 1
    for i in 1:n
          Sm = 0
        for j in 1:m
            Sm += ((p_vec[i]*r*t)^(j-1))/factorial(j-1) 
				#formulas see paper References [1]
        end 
        P_cdf *= (1 - Sm*exp(-p_vec[i]*r*t))        
    end   
    P = 1 - P_cdf
    return P
end 
	
function approximate_moment(n, fun; p_vec = ones(n), q=1, m = 1, r = 1,
	        steps = 10000, normalize = true)
    @assert length(p_vec) == n
    a = 0; b = 0
	ϵ = 0.00001
    while fun(n, b; p_vec = p_vec, m = m, r=r, normalize=normalize) > ϵ
        b += n
			if fun(n, b; p_vec = p_vec, m = m, r=r, normalize=normalize) > 1-ϵ
				a = deepcopy(b)
			end
    end
    δ = (b-a)/steps; t = a:δ:b
    qth_moment = q * (sum(δ .* fun.(n, t; p_vec = p_vec, m = m, r=r, normalize = normalize) .* t.^(q-1)) ) + (a^(q)) #integration exp_ccdf, see paper References [1]
    return qth_moment           
end
	

	
	
function expectation_minsamplesize(n; p_vec = ones(n), m = 1, r = 1, normalize = true)
    @assert length(p_vec) == n
    E = approximate_moment(n, exp_ccdf; p_vec = p_vec, q = 1, m = m, r = r, normalize = normalize)
    return ceil(E)
end

function std_minsamplesize(n; p_vec = ones(n), m = 1, r = 1, normalize = true)
    @assert length(p_vec) == n
    M1 = approximate_moment(n, exp_ccdf; p_vec = p_vec, q=1, m = m, r = r,  normalize = normalize)
    M2 = approximate_moment(n, exp_ccdf; p_vec = p_vec, q=2, m = m, r = r, normalize = normalize)
    var = M2 - M1 - M1^2
    return ceil(sqrt(var))
end
	
function success_probability(n, t; p_vec = ones(n), m = 1, r = 1, normalize = true)   
    P_success = 1 - exp_ccdf(n, t; p_vec = p_vec, m = m, r = r, normalize = normalize) 
    return P_success
end
	
function expectation_fraction_collected(n, t; p_vec = ones(n), r = 1, normalize=true)
    if normalize
        p_vec = p_vec./sum(p_vec)
    end
    frac = sum( (1-(1-p_vec[i])^(t*r)) for i in 1:n )/n
    return frac
end
	
function prob_occurrence_module(p, t, j)
	return (exp(-1*(p*t))*(p*t)^j)/factorial(j) 
end
	
md"  "
end

# ╔═╡ 4d246460-af05-11eb-382b-590e60ba61f5
md"## Collecting Coupons in combinatorial biotechnology

This notebook provides functions and visualizations to determine expected minimum sample sizes for biotechnological experiments, based on the mathematical framework of the Coupon Collector Problem (references see [^1], [^2]).

"

# ╔═╡ a8c81622-194a-443a-891b-bfbabffccff1
begin
md""" 
 
👇 **COMPLETE THE FIELDS BELOW** 👇

№ modules in design space:                       $(@bind n_string TextField(default = "100")) \
	
№ modules per design:                            $(@bind r NumberField(1:20))\
№ complete sets of modules to collect:               $(@bind m NumberField(1:20))\
	
Abundances of modules during library generation:       $(@bind ps Select(["Equal", "Unequal"], default = "Equal"))"""
	
end

# ╔═╡ 45507d48-d75d-41c9-a018-299e209f900e
begin
	n = parse(Int64, n_string);
	if ps == "Equal"
		distribution = "Equal"
	end
		if ps == "Unequal"	
	md""" 	                         ↳     Specify distribution:                         
	$(@bind distribution Select(["Bell curve", "Zipf's law", "Custom vector"], default = " "))"""
		end	
end

# bell curve ipv normale distrbution, neem quantielen, niet samplen, vaste uitkomst

# ╔═╡ b17f3b8a-61ee-4563-97cd-19ff049a8e1e
begin
	if distribution == "Bell curve"					
			md"""                                    pₘₐₓ/pₘᵢₙ:  $(@bind pmaxpmin_str TextField(default = "4")) 
                                            """
			end
end

# ╔═╡ e3b4c2d8-b78c-467e-a863-5eecb8ec58dc
begin
	if distribution == "Zipf's law"
		md"""                                       pₘₐₓ/pₘᵢₙ:   $(@bind pmaxpmin_string TextField(default = "4")) 
                                            """
			end

end

# ╔═╡ 2639e3fb-ccbb-44de-bd15-1c5dbf6c1539
begin
	if distribution == "Custom vector"
				md"""             	       ↳  Enter/load your custom abundances by changing the cell below 👇"""			
		end
end

# ╔═╡ 44d4dfee-3073-49aa-867c-3abea10e6e37
begin
	# To load your custom probability vector from an excell sheet,
	# see for example XLSX package
	# Below, an example of a custom abundance vector is defined using rand
	if distribution == "Custom vector"
		abundances = rand(200:1:400, n)
	end
end

# ╔═╡ f6ebf9fb-0a29-4cb4-a544-6c6e32bedcc4
md"""	
 
🎯 **REPORT**  🎯

**💻 Module probabilities**                                                                                                                       $(@bind show_modprobs Select(["🔻 SHOW ", "🔺 HIDE "], default="🔺 HIDE ") )  \
*How the abundances of the modules are distributed during combinatorial library generation.*
"""

# ╔═╡ b0291e05-776e-49ce-919f-4ad7de4070af
begin
	function p_power(n, k)
    	p = (1:n) .^ -k
    	return p ./ sum(p)
	end

	if ps == "Equal"
	 	
		p_vec = ones(n)./sum(ones(n));
		
	elseif ps == "Unequal"
		if distribution == "Bell curve"
			ratio = parse(Float64, pmaxpmin_str)
			ab1 = 1
			ab2 = ratio*ab1
			μ = (ab1+ab2)/2
			σ = (ab2-ab1)/6
			
			#create fixed distribution of abundances according to percentiles of bell curve
			n_perc_1 = Int(floor(n*0.34)); 
			n_perc_2 = Int(floor(n*0.135));
			n_perc_3 = Int(floor(n*0.0215));
			#n_perc_4 = Int(floor(n*0.0013));
			n_perc_rest = n - 2*n_perc_1 - 2*n_perc_2 - 2*n_perc_3 ;
			p_vec_unnorm = vcat(fill(μ,2*n_perc_1+n_perc_rest), fill(μ+1.5*σ, n_perc_2), fill(μ-1.5*σ, n_perc_2), fill(μ+3*σ, n_perc_3), fill(μ-3*σ, n_perc_3) )
		
			# normalize sum to 1
			p_vec = sort(p_vec_unnorm ./ sum(p_vec_unnorm))
		end
		
		if distribution == "Custom vector"
			p_vec_unnorm = abundances
			p_vec = abundances ./ sum(abundances)
		end
		
		if distribution == "Zipf's law"
			ratio = parse(Float64, pmaxpmin_string)
			p_vec = p_power(n, log(ratio)/log(n))
			p_vec = p_vec ./ sum(p_vec)
		end
	end
	
	if show_modprobs == "🔻 SHOW "   
	
	scatter(p_vec, title = "Probability mass function", ylabel = "module probability pⱼ", xlabel = "module j", label="", size = (700, 400))
	ylims!((0,2*maximum(p_vec)), titlefont=font(10))

	end	
end

# ╔═╡ 87c3f5cd-79bf-4ad8-b7f8-3e98ec548a9f
begin
	if show_modprobs == "🔻 SHOW "  && distribution == "Bell curve"
		histogram(p_vec, normalize=:probability,  bar_edges=false,  size = (650, 340), orientation=:v, bins=[(μ -  3*σ)/sum(p_vec_unnorm), (μ - 2*σ)/sum(p_vec_unnorm), (μ-σ)/sum(p_vec_unnorm), (μ + σ)/sum(p_vec_unnorm), (μ + 2*σ)/sum(p_vec_unnorm), (μ +  3*σ)/sum(p_vec_unnorm)], titlefont=font(10), xguidefont=font(9), yguidefont=font(9))
		# if distribution == "Normally distributed"
		# 	plot!(x->pdf(Normal(μ, σ), x), xlim=xlims())
		# 	xlabel!("Abundance"); ylabel!("probability"); title!("Distribution of module abundances")
		# end
		xlabel!("Probability"); ylabel!("Relative frequency"); title!("Distribution of module probabilities")
	end	
end

# ╔═╡ 2313198e-3ac9-407b-b0d6-b79e02cefe35
begin
	if show_modprobs == "🔻 SHOW "  && distribution == "Bell curve"
md"""For $n_string modules of which the probabilities form a bell curve with ratio pₘₐₓ/pₘᵢₙ = $pmaxpmin_str , we follow the percentiles of a normal distribution to generate the probability vector.

We consider μ to be the mean module probability and σ to be the standard deviation of the module probabilities.
		
According to the percentiles
- 68% of the module probabilities lies in the interval [μ - σ, μ + σ], 
- 95% of falls into the range [μ - 2σ, μ + 2σ] and 
- 99.7% lies in [μ - 3σ, μ +3σ]. 
		
We use the ratio pₘₐₓ/pₘᵢₙ to fix the width of the interval [μ - 3σ, μ +3σ]. (We assume that pₘₐₓ = μ +3σ and pₘᵢₙ = μ - 3σ and calculate μ and σ from this assumption). In addition, we make sure the sum of the probability vector sums up to 1.
		
As a result, we get:
-  $(n_perc_1+n_perc_rest) modules with a probability of $(µ/sum(p_vec_unnorm))
-  $(n_perc_2)  modules with a probability of $((μ+1.5*σ)/sum(p_vec_unnorm))
-  $(n_perc_2)  modules with a probability of $((μ-1.5*σ)/sum(p_vec_unnorm))
-  $(n_perc_3)  modules with a probability of $((μ+2.5*σ)/sum(p_vec_unnorm))
-  $(n_perc_3)  modules with a probability of $((μ-2.5*σ)/sum(p_vec_unnorm))"""
	end	
end

# ╔═╡ f098570d-799b-47e2-b692-476a4d95825b
if show_modprobs == "🔻 SHOW " 
md"Each biological design in the design space is built by choosing $r module(s) (with replacement) out of a set of $n_string modules according to the module probabilities visualized above."
end

# ╔═╡ 85c0bd2f-e6a6-4feb-8bd1-f8bb058e10e0


# ╔═╡ caf67b2f-cc2f-4d0d-b619-6e1969fabc1a
md""" **💻 Expected minimum sample size**                                                                                                             $(@bind show_E Select(["🔻 SHOW ", "🔺 HIDE "], default="🔺 SHOW ")) 
\
*The expected minimum number of designs to observe each module at least $m times in the sampled set of designs.* """   

# ╔═╡ 6f14a72c-51d3-4759-bb8b-10db1dc260f0
begin
	if show_E == "🔻 SHOW "   
		E = Int(expectation_minsamplesize(n; p_vec = p_vec, m=m, r = r))
		sd = Int(std_minsamplesize(n; p_vec = p_vec, m=m, r = r))
		
			md""" 
     `Expected minimum sample size    `     = **$E designs**\
		
     `Standard deviation              `                = **$sd designs**  	"""
	end
	# begin
		
	# 	#E_vec = []
	# 	#sd_vec = []
			 
	# 	#if ps == "Unequal" && probs_unequal_norm
	# 			#iter = 10
	# 			#for i in 1:iter
	# 				#p_vec_i = rand(Normal(μ,  σ), n)
	# 				#p_vec_i = p_vec_i ./ sum(p_vec_i)
	# 				#E_i = expectation_minsamplesize(n; p_vec = p_vec_i, m=m, q = q)
	# 				#sd_i = std_minsamplesize(n; p_vec = p_vec_i, m=m, q=q)
	# 				#push!(E_vec, E_i)
	# 				#push!(sd_vec, sd_i)
	# 			#end
	# 			#E = Int(ceil(mean(E_vec)))
	# 			#sd = Int(ceil(mean(sd_vec)))
	# 			#E_CI_lhs = Int(ceil( E - quantile(Normal(), 1-0.05/2)*sd/sqrt(iter)))
	# 			#E_CI_rhs = Int(ceil(E + quantile(Normal(), 1-0.05/2)*sd/sqrt(iter)))
	# 			#sd_CI_lhs = Int(ceil( sd - quantile(Normal(), 1-0.05/2)*sd/sqrt(iter)))
	# 			#sd_CI_rhs = Int(ceil(sd + quantile(Normal(), 1-0.05/2)*sd/sqrt(iter)))
				
			
	# 		#md""" 
	# 		#``` 
	# 		#Expected minimum sample size E[Tp]
	# 		#```		 	
	# 		#= **$E designs**    -------- 95% CI :  [$E_CI_lhs, $E_CI_rhs]
		
	# 		#``` 
	# 		#Standard deviation sd[Tp]  
	# 		#```	
		
	# 		#= **$sd designs**   -------- 95% CI :  [$sd_CI_lhs, $sd_CI_rhs]
		
	# 		#---------------
	# 		#"""
		
	# 		#else
	
	# #	E = expectation_minsamplesize(n; p_vec = p_vec, m=m, q = q)
	# #	sd = std_minsamplesize(n; p_vec = p_vec, m=m, q=q)
			
			
	# #		md""" 
	# #		``` 
	# #		Expected minimum sample size E[Tp]
	# #		```		 	
	# #		= **$E designs**    
		
	# #		``` 
	# #		Standard deviation sd[Tp]  
	# #		```	
		
	# #		= **$sd designs**   
		
	# #		---------------
	# #		"""
				 
	# 		#end
			
			
		 
	# #end
end

# ╔═╡ f1e180e5-82a7-4fab-b894-75be4627af5d


# ╔═╡ 22fe8006-0e81-4e0a-a460-28610a55cd97
md""" **💻 Success probability**                                                                                                                  $(@bind show_success Select(["🔻 SHOW ", "🔺 HIDE "], default="🔺 HIDE ") )\

*The probability that the minimum number of designs T is smaller than or equal to a given sample size t.* """

# ╔═╡ db4371e4-7f86-4db3-b076-12f6cd220b89
begin
	if show_success == "🔻 SHOW " 
		md"""    👉 Enter your sample size of interest: $(@bind sample_size_1_string TextField(default="500"))""" 
		
	end
	#genereer tabel + download knop
end

# ╔═╡ 317995ed-bdf4-4f78-bd66-a39ffd1dc452
begin
	if show_success == "🔻 SHOW " 
	sample_size_1 = parse(Int64, sample_size_1_string);
	
	p_success = success_probability(n, sample_size_1; p_vec = p_vec, m = m, r = r)
	
	md""" 
              ↳ `Success probability F(t)`  = **$p_success**\
	"""
	end
end

# ╔═╡ 3039ac2b-656e-4c2b-9036-cb1d9cdc0790


# ╔═╡ ca5a4cef-df67-4a5e-8a86-75a9fe8c6f37
if show_success == "🔻 SHOW " 
	md"*A curve describing the success probability in function of sample size.*"
end

# ╔═╡ 9616af0e-810c-4e6a-bc67-cb70e5e620f5


# ╔═╡ 24f7aae7-d37a-4db5-ace0-c910b178da88
begin
if show_success == "🔻 SHOW " 
	
sample_size_initial = 5
	while (1 - success_probability(n, sample_size_initial; p_vec = p_vec, r = r, m = m)) > 0.0005
		global sample_size_initial += n/10
	end
		
	sample_sizes = 0:n/10:sample_size_initial
	successes = success_probability.(n, sample_sizes; p_vec = p_vec, r = r, m = m)
plot(sample_sizes, successes, title = "Success probability in function of sample size", xlabel = "sample size s", ylabel= "P(s ≤ Sₘᵢₙ)", label = "", legend=:bottomright, size=(600,400), seriestype=:scatter, titlefont=font(10),xguidefont=font(9), yguidefont=font(9))
		end
	 
end

# ╔═╡ 4902d817-3967-45cd-a283-b2872cf1b49c


# ╔═╡ 37f951ee-885c-4bbe-a05f-7c5e48ff4b6b
begin
	#following one-sided version of Chebyshev's inequality.
	
 
	function chebyshev_onesided_larger(X, μ, σ)
		X_μ = X - μ
		return σ^2 / (σ^2 + X_μ^2)
	end
	function chebyshev_onesided_smaller(X, μ, σ)
		X_μ = μ - X
		return σ^2 / (σ^2 + X_μ^2)
	end
if show_success == "🔻 SHOW "
if sample_size_1 < E
	compare = "smaller"
		if sample_size_1 <= n/r
			print_sentence = "P(minimum sample size ≤ $sample_size_1) = 0."
		else
	prob_chebyshev = chebyshev_onesided_smaller(sample_size_1, E, sd)
	print_sentence = "P(minimum sample size ≤ $sample_size_1) ≤ $prob_chebyshev. "
		end
		
elseif sample_size_1 > E
	compare = "greater"
	prob_chebyshev = chebyshev_onesided_larger(sample_size_1, E, sd)
	print_sentence = "P(minimum sample size ≥ $sample_size_1) ≤ $prob_chebyshev. "	
		
	elseif sample_size_1==E
		print_sentence = "P(minimum sample size ≤ $sample_size_1 OR minimum sample size ≥ $sample_size_1) ≤ 1."
		
end

	md"""*Upper bound on probability that minimum sample size is smaller than given sample size t, according to Chebychev's inequality.*:
		
		
	                            $print_sentence"""
	end
end

# ╔═╡ 702b158b-4f1c-453f-9e70-c00ec22226c3


# ╔═╡ dc696281-7a5b-4568-a4c2-8dde90af43f0
md""" **💻 Expected observed fraction of the total number of modules**                $(@bind show_satur Select(["🔻 SHOW ", "🔺 HIDE "], default="🔺 HIDE "))\
*The fraction of the total number of available modules that is expected to be observed after collecting a given number of designs.*"""

# ╔═╡ eb92ff7c-0140-468c-8b32-f15d1cf15913
if show_satur == "🔻 SHOW " 
		md"""
   👉 Enter your sample size of interest: $(@bind sample_size_2_string TextField(default="50")) """ 
end

# ╔═╡ f0eaf96b-0bc0-4194-9a36-886cb1d66e00
begin
	if show_satur == "🔻 SHOW " 
	sample_size_2 = parse(Int64, sample_size_2_string)
	E_fraction = expectation_fraction_collected(n, sample_size_2; p_vec = p_vec, r = r)
	
	md""" 	            ↳ `Expected fraction observed`	= **$E_fraction**
	"""	
	end
end

# ╔═╡ 8ce0d3d7-8081-4d08-9189-595e3dc1814f


# ╔═╡ 0099145a-5460-4549-9513-054bc1b04eea
if  show_satur == "🔻 SHOW " 
md""" *A curve describing the expected fraction of modules observed in function of sample size.* """
	end

# ╔═╡ 7968de5e-5ae8-4ab4-b089-c3d33475af2f
begin
	if show_satur == "🔻 SHOW " 
global sample_size_initial_frac = 5
		while (1 - expectation_fraction_collected(n, sample_size_initial_frac; p_vec = p_vec, r = r)) > 0.0005
		global	 sample_size_initial_frac += n/10
		end
	
	sample_sizes_frac = 0 : n/10 : sample_size_initial_frac
	
	fracs = expectation_fraction_collected.(n, sample_sizes_frac; p_vec = p_vec, r = r)
	
	plot(sample_sizes_frac, fracs, title = "Expected observed fraction of the total number of modules", 
	    xlabel = "sample size", seriestype=:scatter, 
	    ylabel= "E[fraction observed]", label = "", size=(700,400), xguidefont=font(9), yguidefont=font(9), titlefont=font(10))
end
end

# ╔═╡ 0b95ccff-4c7b-400d-be61-8ea056ccc87f


# ╔═╡ f92a6b6e-a556-45cb-a1ae-9f5fe791ffd2
md""" **💻 Occurrence of a specific module**                                                                                                       $(@bind show_occ Select(["🔻 SHOW ", "🔺 HIDE "], default="🔺 HIDE "))\
*How many times one can expect to have collected a specific module in a sample of a given size.*"""

# ╔═╡ ec2a065f-0dc7-44d4-a18b-6c6a228b3ffc
if show_occ == "🔻 SHOW " && distribution != "Zipf's law"
	md"""    👉 Enter the probability of the module of interest: $(@bind p_string TextField(default="0.01"))\
	    👉 Enter the sample size of interest:                $(@bind sample_size_3_string TextField(default="300"))
	""" 	
	
end

# ipv probabiliteit --> rank i: sorteer modules

# ╔═╡ 0e39a993-bb2f-4897-bfe2-5128ec62bef9
if show_occ == "🔻 SHOW " && distribution == "Zipf's law"
	md"""    👉 Enter the rank of the module of interest:        $(@bind rank_string TextField(default="5"))\
	    👉 Enter the sample size of interest:                $(@bind sample_size_4_string TextField(default="500"))
	""" 	
	
end

# ipv probabiliteit --> rank i: sorteer modules

# ╔═╡ 6acb0a97-6469-499f-a5cf-6335d6aa909a
begin

	
if show_occ == "🔻 SHOW " 
	if distribution != "Zipf's law"
	p = parse(Float64, p_string)
	sample_size_3 = parse(Int64, sample_size_3_string)
 	# module_ = 1
# 	p = p_vec[module_]
# 	p = maximum(p_vec) 
	ed = Int(floor(sample_size_3*p))
	j = 0:1:minimum([20, 2*ed])
			
	x  = prob_occurrence_module.(p, sample_size_3, j)
	 plot(j,x, seriestype=[:line, :scatter], xlabel="№ occurrences in sample", ylabel="probability p", title="Probability on № of occurrences for specific module", label="", size=((600,300)), titlefont=font(10), xguidefont=font(9), yguidefont=font(9))
	
		else
		rank = parse(Int64, rank_string)
		p = p_vec[rank]
	sample_size_4 = parse(Int64, sample_size_4_string)
 	# module_ = 1
# 	p = p_vec[module_]
# 	p = maximum(p_vec) 
			ed = Int(floor(sample_size_4*p))
	j = 0:1:minimum([20, 2*ed])
			
	x  = prob_occurrence_module.(p, sample_size_4, j)
	 plot(j,x, seriestype=[:line, :scatter], xlabel="№ occurrences in sample", ylabel="probability p", title="Probability on № of occurrences for specific module", size=((600,300)), label="",titlefont=font(10), xguidefont=font(9), yguidefont=font(9))	
			
		end
	end
end

# ╔═╡ 595423df-728b-43b1-ade4-176785c54be3
begin
	if show_occ == "🔻 SHOW " 

	
	md""" 	            ↳ `Expected number of times observed`	≈ **$ed**
		"""
	end
end

# ╔═╡ fbffaab6-3154-49df-a226-d5810d0b7c38
md"""## References"""

# ╔═╡ 1f48143a-2152-4bb9-a765-a25e70c281a3
md"""[^1]:  Doumas, A. V., & Papanicolaou, V. G. (2016). *The coupon collector’s problem revisited: generalizing the double Dixie cup problem of Newman and Shepp.* ESAIM: Probability and Statistics, 20, 367-399.

[^2]: Boneh, A., & Hofri, M. (1997). *The coupon-collector problem revisited—a survey of engineering problems and computational methods.* Stochastic Models, 13(1), 39-66.



"""


# ╔═╡ Cell order:
# ╟─4d246460-af05-11eb-382b-590e60ba61f5
# ╟─dc734eab-c244-4337-a0f3-469d77045eec
# ╟─e1a7f2da-a38b-4b3c-a238-076769e46408
# ╟─a8c81622-194a-443a-891b-bfbabffccff1
# ╟─45507d48-d75d-41c9-a018-299e209f900e
# ╟─b17f3b8a-61ee-4563-97cd-19ff049a8e1e
# ╟─e3b4c2d8-b78c-467e-a863-5eecb8ec58dc
# ╟─2639e3fb-ccbb-44de-bd15-1c5dbf6c1539
# ╟─44d4dfee-3073-49aa-867c-3abea10e6e37
# ╟─f6ebf9fb-0a29-4cb4-a544-6c6e32bedcc4
# ╟─87c3f5cd-79bf-4ad8-b7f8-3e98ec548a9f
# ╟─2313198e-3ac9-407b-b0d6-b79e02cefe35
# ╟─b0291e05-776e-49ce-919f-4ad7de4070af
# ╟─f098570d-799b-47e2-b692-476a4d95825b
# ╟─85c0bd2f-e6a6-4feb-8bd1-f8bb058e10e0
# ╟─caf67b2f-cc2f-4d0d-b619-6e1969fabc1a
# ╟─6f14a72c-51d3-4759-bb8b-10db1dc260f0
# ╟─f1e180e5-82a7-4fab-b894-75be4627af5d
# ╟─22fe8006-0e81-4e0a-a460-28610a55cd97
# ╟─db4371e4-7f86-4db3-b076-12f6cd220b89
# ╟─317995ed-bdf4-4f78-bd66-a39ffd1dc452
# ╟─3039ac2b-656e-4c2b-9036-cb1d9cdc0790
# ╟─ca5a4cef-df67-4a5e-8a86-75a9fe8c6f37
# ╟─9616af0e-810c-4e6a-bc67-cb70e5e620f5
# ╟─24f7aae7-d37a-4db5-ace0-c910b178da88
# ╟─4902d817-3967-45cd-a283-b2872cf1b49c
# ╟─37f951ee-885c-4bbe-a05f-7c5e48ff4b6b
# ╟─702b158b-4f1c-453f-9e70-c00ec22226c3
# ╟─dc696281-7a5b-4568-a4c2-8dde90af43f0
# ╟─eb92ff7c-0140-468c-8b32-f15d1cf15913
# ╟─f0eaf96b-0bc0-4194-9a36-886cb1d66e00
# ╟─8ce0d3d7-8081-4d08-9189-595e3dc1814f
# ╟─0099145a-5460-4549-9513-054bc1b04eea
# ╟─7968de5e-5ae8-4ab4-b089-c3d33475af2f
# ╟─0b95ccff-4c7b-400d-be61-8ea056ccc87f
# ╟─f92a6b6e-a556-45cb-a1ae-9f5fe791ffd2
# ╟─ec2a065f-0dc7-44d4-a18b-6c6a228b3ffc
# ╟─0e39a993-bb2f-4897-bfe2-5128ec62bef9
# ╟─6acb0a97-6469-499f-a5cf-6335d6aa909a
# ╟─595423df-728b-43b1-ade4-176785c54be3
# ╟─fbffaab6-3154-49df-a226-d5810d0b7c38
# ╟─1f48143a-2152-4bb9-a765-a25e70c281a3
