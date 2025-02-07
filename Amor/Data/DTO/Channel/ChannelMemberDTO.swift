//
//  ChannelMemberDTO.swift
//  Amor
//
//  Created by 홍정민 on 11/25/24.
//

import Foundation

struct ChannelMemberDTO: Decodable {
    let user_id: String
    let email: String
    let nickname: String
    let profileImage: String?
}

extension ChannelMemberDTO {
    func toDomain() -> ChannelMember {
        return ChannelMember(
            user_id: user_id,
            email: email,
            nickname: nickname,
            profileImage: profileImage
        )
    }
}
