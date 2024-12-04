//
//  HomeCoordinator.swift
//  Amor
//
//  Created by 김상규 on 11/22/24.
//

import UIKit

final class HomeCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    var sideMenuViewController: SideSpaceMenuViewController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let homeVC: HomeViewController = DIContainer.shared.resolve()
        homeVC.tabBarItem = UITabBarItem(
            title: "홈",
            image: Design.TabImage.homeUnselected,
            selectedImage: Design.TabImage.homeSelected
        )
        homeVC.coordinator = self
        navigationController.pushViewController(homeVC, animated: true)
    }
    
    func showChatFlow(channel: Channel) {
        let chatCoordinator = ChatCoordinator(navigationController: navigationController, channel: channel)
        chatCoordinator.start()
    }
    
    func showAddChannelFlow() {
        let coordinator = AddChannelCoordinator(navigationController: navigationController)
        coordinator.delegate = navigationController.viewControllers.first(where: { $0 is HomeViewController }) as? AddChannelDelegate
        coordinator.start()
    }
    
    func presentSideMenuFlow() {
        let coordinator = SideSpaceMenuCoordinator(navigationController: navigationController)
        coordinator.parentCoordinator = self
        // childCoordinators에 SideSpaceMenuCoordinator 추가
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func showLoginFlow() {
        if let tabCoordinator = parentCoordinator as? TabCoordinator, let appCoordinator = tabCoordinator.parentCoordinator as? AppCoordinator {
            // 메인 플로우(TabCoordinator) 제거
            appCoordinator.childCoordinators.removeAll(where: { $0 is TabCoordinator })
            appCoordinator.showUserFlow()
        }
    }
    
    func showDMTabFlow() {
        if let tabBarController = navigationController.tabBarController {
            tabBarController.selectedIndex = 1
        }
    }
    
    func dismissSideSpaceMenuFlow() {
        if let sideSpaceMenuCoordinator = childCoordinators.first as? SideSpaceMenuCoordinator {
            sideSpaceMenuCoordinator.dismissSideSpaceMenuFlow()
            // childCoordinators 내의 SideSpaceMenuCoordinator 삭제
            childCoordinators.removeAll()
        }
    }
}
