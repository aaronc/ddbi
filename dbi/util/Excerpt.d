module dbi.util.Excerpt;

debug char[] excerpt(char[] val)
{
	const size_t max = 50;
	if(val.length < max) return val;
	else return val[0..max/2-2] ~ "..." ~ val[$ - (max/2-2) .. $]; 
}