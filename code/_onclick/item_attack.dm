
// Called when the item is in the active hand, and clicked; alternately, there is an 'activate held object' verb or you can hit pagedown.
/obj/item/proc/attack_self(mob/user)
	return

// No comment
/atom/proc/attackby(obj/item/W, mob/living/user)
	return

/atom/movable/attackby(obj/item/W, mob/living/user)
	if(W)
		if(!(W.flags_item & NOBLUDGEON))
			visible_message(SPAN_DANGER("[src] has been hit by [user] with [W]."), null, 5)
			user.animation_attack_on(src)
			user.flick_attack_overlay(src, "punch")

/mob/living/attackby(obj/item/I, mob/user)
	if(istype(I) && ismob(user))
		return I.attack(src, user)


// Proximity_flag is 1 if this afterattack was called on something adjacent, in your square, or on your person.
// Click parameters is the params string from byond Click() code, see that documentation.
/obj/item/proc/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	return FALSE


/obj/item/proc/attack(mob/living/M, mob/living/user, def_zone)
	if(flags_item & NOBLUDGEON)
		return FALSE

	if (!istype(M)) // not sure if this is the right thing...
		return FALSE

	if (M.can_be_operated_on()) //Checks if mob is lying down on table for surgery
		if (do_surgery(M,user,src))
			return FALSE

	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(!C.species.melee_allowed)
			to_chat(C, SPAN_DANGER("You are currently unable to attack."))
			return FALSE

	var/showname = "."
	if(user)
		if(M == user)
			showname = " by themselves."
		else
			showname = " by [user]."
	if(!(user in viewers(M, null)))
		showname = "."

	if (user.client && user.client.prefs && user.client.prefs.toggle_prefs & TOGGLE_HELP_INTENT_SAFETY && user.a_intent == HELP_INTENT)
		playsound(loc, 'sound/effects/pop.ogg', 25, 1)
		user.visible_message(SPAN_NOTICE("[M] has been poked with [src][showname]"),\
			SPAN_NOTICE("You poke [M == user ? "yourself":M] with [src]."), null, 4)

		return FALSE

	/////////////////////////
	user.lastattacked = M
	M.lastattacker = user
	user.attack_log += "\[[time_stamp()]\]<font color='red'> Attacked [M.name] ([M.ckey]) with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])</font>"
	M.attack_log += "\[[time_stamp()]\]<font color='orange'> Attacked by [user.name] ([user.ckey]) with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])</font>"
	msg_admin_attack("[key_name(user)] attacked [key_name(M)] with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)]) at ([src.loc.x],[src.loc.y],[src.loc.z]) (<A HREF='?_src_=admin_holder;adminplayerobservecoodjump=1;X=[src.loc.x];Y=[src.loc.y];Z=[src.loc.z]'>JMP</a>)" )

	/////////////////////////

	add_fingerprint(user)

	var/power = force
	if(HULK in user.mutations)
		power *= 2

	if(user.mind && user.mind.cm_skills)
		power = round(power * (1 + 0.3*user.mind.cm_skills.get_skill_level(SKILL_MELEE_WEAPONS))) //30% bonus per melee level

	if(!ishuman(M))
		var/used_verb = "attacked"
		if(attack_verb && attack_verb.len)
			used_verb = pick(attack_verb)
		user.visible_message(SPAN_DANGER("[M] has been [used_verb] with [src][showname]."), \
			SPAN_DANGER("You [used_verb] [M == user ? "yourself":M] with [src]."), null, 5)

		user.animation_attack_on(M)
		user.flick_attack_overlay(M, "punch")
		if(isXeno(M))
			var/mob/living/carbon/Xenomorph/XNO = M
			if (isYautja(user))
				power *= 1.1 // Preds get bonus melee damage vs xenos

			power = armor_damage_reduction(config.xeno_melee, power, XNO.armor_deflection + XNO.armor_deflection_buff, 20, 0, 0, XNO.armor_integrity)
			var/armor_punch = armor_break_calculation(config.xeno_melee, power, XNO.armor_deflection + XNO.armor_deflection_buff, 20, 0, 0, XNO.armor_integrity)
			XNO.apply_armorbreak(armor_punch)
		if(hitsound)
			playsound(loc, hitsound, 25, 1)
		switch(damtype)
			if("brute")
				M.apply_damage(power,BRUTE)
			if("fire")
				if (!(COLD_RESISTANCE in M.mutations))
					M.apply_damage(power,BURN)
					to_chat(M, SPAN_WARNING("It burns!"))
		if(power > 5)
			M.last_damage_source = initial(name)
			M.last_damage_mob = user
			user.track_hit(initial(name))
			if(user.faction == M.faction)
				user.track_friendly_fire(initial(name))
		M.updatehealth()
	else
		var/mob/living/carbon/human/H = M
		var/hit = H.attacked_by(src, user, def_zone)
		if (hit && hitsound)
			playsound(loc, hitsound, 25, 1)
		return hit
	return TRUE
