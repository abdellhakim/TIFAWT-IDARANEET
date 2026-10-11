import 'package:flutter/material.dart';

import '../models/opportunity.dart';
import '../models/profile_enums.dart';

IconData interestIcon(Interest i) => switch (i) {
  Interest.digital => Icons.computer_rounded,
  Interest.agriculture => Icons.agriculture_rounded,
  Interest.tourism => Icons.luggage_rounded,
  Interest.commerce => Icons.storefront_rounded,
  Interest.marketing => Icons.campaign_rounded,
  Interest.crafts => Icons.handyman_rounded,
  Interest.renewableEnergy => Icons.solar_power_rounded,
  Interest.logistics => Icons.local_shipping_rounded,
  Interest.foodProcessing => Icons.restaurant_rounded,
  Interest.care => Icons.healing_rounded,
};

IconData skillIcon(Skill s) => switch (s) {
  Skill.computing => Icons.keyboard_rounded,
  Skill.communication => Icons.forum_rounded,
  Skill.sales => Icons.sell_rounded,
  Skill.languages => Icons.translate_rounded,
  Skill.programming => Icons.code_rounded,
  Skill.management => Icons.calculate_rounded,
  Skill.farming => Icons.eco_rounded,
  Skill.manualWork => Icons.build_rounded,
};

IconData objectiveIcon(Objective o) => switch (o) {
  Objective.employment => Icons.work_rounded,
  Objective.training => Icons.school_rounded,
  Objective.studies => Icons.menu_book_rounded,
  Objective.entrepreneurship => Icons.rocket_launch_rounded,
  Objective.skills => Icons.trending_up_rounded,
};

IconData situationIcon(CurrentSituation s) => switch (s) {
  CurrentSituation.jobSeeking => Icons.search_rounded,
  CurrentSituation.trainingSeeking => Icons.school_outlined,
  CurrentSituation.schoolDropout => Icons.backpack_outlined,
  CurrentSituation.inactive => Icons.hourglass_empty_rounded,
};

IconData typeIcon(OpportunityType t) => switch (t) {
  OpportunityType.formation => Icons.school_rounded,
  OpportunityType.internship => Icons.badge_rounded,
  OpportunityType.job => Icons.work_rounded,
  OpportunityType.support => Icons.support_agent_rounded,
  OpportunityType.entrepreneurship => Icons.rocket_launch_rounded,
  OpportunityType.workshop => Icons.groups_rounded,
  OpportunityType.program => Icons.volunteer_activism_rounded,
};
